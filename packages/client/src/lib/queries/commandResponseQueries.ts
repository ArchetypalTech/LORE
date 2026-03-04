import { InitDojo } from "../dojo";
import { ToriiQueryBuilder, ClauseBuilder, SDK } from "@dojoengine/sdk";
import { bigintToHex128 } from "@/lib/utils/utils";
import { SchemaType, Player, PlayerStory, StoryLine, TrailProgress } from "@/lib/dojo_bindings/typescript/models.gen";
import { fromWei, queryErrorLocation } from "../queriesPanel/uiPanelQueries";
import JSONbig from "json-bigint";

const trailID: bigint = 0n;
// Call queries and generate json file
export const queryGameData = async (): Promise<void> => {
  const { sdk } = await InitDojo();
  try {
    // ---------------------------------
    // 1 Query PlayerStories & Players
    // ---------------------------------
    const [playerStories, players] = await queryPlayerStories(sdk);

    // ---------------------------------
    // 2 Query Error + Command pairs
    // ---------------------------------
    const errorCommandPairs = await queryStorylinesErrorsCommands(sdk);

    // ---------------------------------
    // 3 Flatten pairs → StoryLine[]
    // ---------------------------------
    const allStorylinesErrors: StoryLine[] = [];
    errorCommandPairs.forEach(([error, command]) => {
      allStorylinesErrors.push(error);
      allStorylinesErrors.push(command);
    });

    // ---------------------------------
    // 4 game_id -> StoryLine[]
    // ---------------------------------
    const storylinesByGame: Record<string, StoryLine[]> = {};

    for (const line of allStorylinesErrors) {
      const gameId = line.game_id.toString();
      if (!storylinesByGame[gameId]) {
        storylinesByGame[gameId] = [];
      }
      storylinesByGame[gameId].push(line);
    }

    // Sort latest → oldest
    Object.values(storylinesByGame).forEach((lines) => {
      lines.sort((a, b) =>
        BigInt(a.key.toString()) < BigInt(b.key.toString()) ? 1 : -1
      );
    });

    // ---------------------------------
    // 5 game_id -> player address + is_dead
    // ---------------------------------
    const gameToPlayer: Record<
      string,
      { address: string; isDead: boolean }
    > = {};

    players.forEach((p) => {
      gameToPlayer[p.game_id.toString()] = {
        address: p.address,
        isDead: p.is_dead,
      };
    });

    // ---------------------------------
    // 6 game_id -> PlayerStory
    // ---------------------------------
    const playerStoryByGame: Record<string, PlayerStory> = {};
    playerStories.forEach((ps) => {
      playerStoryByGame[ps.game_id.toString()] = ps;
    });

    // ---------------------------------
    // 7 Final grouped structure
    // ---------------------------------
    const grouped: Record<
      string,
      Record<
        string,
        {
          latest_story_line: bigint;
          free_actions_count: number;
          sub_actions_count: number;
          paid_actions_count: number;
          trailProgress?: {
            percentage: string;
            completed: boolean;
            isDead: boolean;
          };
          storylines: (StoryLine & { locationName?: string })[];
        }
      >
    > = {};

    const gameIds = Object.keys(playerStoryByGame);

    // Use concurrency limit (adjust if needed)
    const CONCURRENCY_LIMIT = 8;

    await mapWithConcurrency(gameIds, CONCURRENCY_LIMIT, async (gameIdStr) => {
      const playerData = gameToPlayer[gameIdStr];
      if (!playerData) return;

      const ps = playerStoryByGame[gameIdStr];
      const { address: playerAddress, isDead } = playerData;

      if (!grouped[playerAddress]) {
        grouped[playerAddress] = {};
      }

      const gameIdBigInt = BigInt(gameIdStr);

      const trailProgressEntity = await queryTrailProgress(
        sdk,
        gameIdBigInt,
        trailID
      );

      const enrichedStorylines = await mapWithConcurrency(
        storylinesByGame[gameIdStr] ?? [],
        8,
        async (line) => {
          const locationEntity = await queryErrorLocation(
            BigInt(line.location.toString())
          );

          return {
            ...line,
            locationName: locationEntity?.name?.toString() ?? "",
          };
        }
      );

      grouped[playerAddress][gameIdStr] = {
        latest_story_line: BigInt(ps.story_line.toString()),
        free_actions_count: fromWei(ps.free_actions_count.toString()),
        sub_actions_count: fromWei(ps.sub_actions_count.toString()),
        paid_actions_count: fromWei(ps.paid_actions_count.toString()),

        trailProgress: trailProgressEntity
          ? {
              percentage: trailProgressEntity.percentage?.toString() ?? "0",
              completed: trailProgressEntity.completed ?? false,
              isDead,
            }
          : {
              percentage: "0",
              completed: false,
              isDead,
            },

        storylines: enrichedStorylines,
      };
    });

    // ---------------------------------
    // 8 EXPORT SECTION (JSON + CSV)
    // ---------------------------------

    const now = new Date();
    const formatter = new Intl.DateTimeFormat("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });

    const formattedDate = formatter.format(now).replace(/ /g, "_");
    const timestampISO = now.toISOString();

    // ---------------- JSON ----------------
    const jsonFilename = `player_data_${formattedDate}.json`;
    const json = JSONbig.stringify(grouped, null, 2);

    const jsonBlob = new Blob([json], { type: "application/json" });
    const jsonUrl = URL.createObjectURL(jsonBlob);

    const jsonLink = document.createElement("a");
    jsonLink.href = jsonUrl;
    jsonLink.download = jsonFilename;
    jsonLink.click();
    URL.revokeObjectURL(jsonUrl);

    // ---------------- CSV PREP ----------------
    const currentRows: Record<string, any>[] = [];
    const historicalRows: Record<string, any>[] = [];
    const storylineRows: Record<string, any>[] = [];
    const trailProgressRows: Record<string, any>[] = [];

    for (const playerAddress in grouped) {
      for (const gameId in grouped[playerAddress]) {
        const game = grouped[playerAddress][gameId];

        const baseRow = {
          Snapshot_Timestamp: timestampISO,
          Player_Address: playerAddress,
          Game_ID: gameId,
          Latest_Story_Line: Number(game.latest_story_line),
          Free_Actions: game.free_actions_count,
          Sub_Actions: game.sub_actions_count,
          Paid_Actions: game.paid_actions_count,
        };

        currentRows.push(baseRow);
        historicalRows.push(baseRow);

        // ---- Storylines ----
        for (const line of game.storylines) {
          storylineRows.push({
            Snapshot_Timestamp: timestampISO,
            Player_Address: playerAddress,
            Game_ID: gameId,
            Storyline_Key: Number(line.key),
            Location_Name: line.locationName ?? "",
            Line_Type: line.line_type,
            Line_Text: line.line,
          });
        }

        // ---- Trail Progress ----
        trailProgressRows.push({
          Snapshot_Timestamp: timestampISO,
          Player_Address: playerAddress,
          Game_ID: gameId,
          Trail_ID: trailID.toString(),
          Percentage: game.trailProgress?.percentage ?? "0",
          Completed: game.trailProgress?.completed ?? false,
          Is_Dead: game.trailProgress?.isDead ?? false,
        });
      }
    }

    // ---------------- EXPORT CURRENT CSV ----------------
    const currentCSV = convertToCSV(currentRows);
    const currentBlob = new Blob([currentCSV], { type: "text/csv" });
    const currentUrl = URL.createObjectURL(currentBlob);

    const currentLink = document.createElement("a");
    currentLink.href = currentUrl;
    currentLink.download = `player_current_${formattedDate}.csv`;
    currentLink.click();
    URL.revokeObjectURL(currentUrl);

    // ---------------- EXPORT HISTORICAL CSV ----------------
    const historicalCSV = convertToCSV(historicalRows);
    const historicalBlob = new Blob([historicalCSV], { type: "text/csv" });
    const historicalUrl = URL.createObjectURL(historicalBlob);

    const historicalLink = document.createElement("a");
    historicalLink.href = historicalUrl;
    historicalLink.download = `player_historical_${formattedDate}.csv`;
    historicalLink.click();
    URL.revokeObjectURL(historicalUrl);

    // ---------------- EXPORT STORYLINES CSV ----------------
    const storylineCSV = convertToCSV(storylineRows);
    const storylineBlob = new Blob([storylineCSV], { type: "text/csv" });
    const storylineUrl = URL.createObjectURL(storylineBlob);

    const storylineLink = document.createElement("a");
    storylineLink.href = storylineUrl;
    storylineLink.download = `player_storylines_${formattedDate}.csv`;
    storylineLink.click();
    URL.revokeObjectURL(storylineUrl);

    // ---------------- EXPORT TRAIL PROGRESS CSV ----------------
    const trailCSV = convertToCSV(trailProgressRows);
    const trailBlob = new Blob([trailCSV], { type: "text/csv" });
    const trailUrl = URL.createObjectURL(trailBlob);

    const trailLink = document.createElement("a");
    trailLink.href = trailUrl;
    trailLink.download = `player_trailprogress_${formattedDate}.csv`;
    trailLink.click();

    URL.revokeObjectURL(trailUrl);

  } catch (error) {
    console.error("Error querying or exporting grouped PlayerStories:", error);
    throw error;
  }
};

// Query all the PlayerStory
const queryPlayerStories = async (sdk: SDK<SchemaType>): Promise<[(PlayerStory[]), Player[]]> => {
	let playerStory: PlayerStory[] = [];
  let players: Player[] = [];

	try {
		const query = new ToriiQueryBuilder<SchemaType>()
			.withCursor("")
			.withLimit(3000)
			.includeHashedKeys()
			.withEntityModels(["lore-PlayerStory"]);

		const result = await sdk.getEntities({ query });

		result.getItems().forEach((entity) => {
			const model = entity.models?.lore?.PlayerStory;
			if (
				model &&
				model.game_id !== undefined &&
				model.story_line !== undefined 
			) {
				playerStory.push({
					game_id: model.game_id,
					story_line: model.story_line,
          free_actions_count: (model.free_actions_count?.toString() ?? "0"),
          sub_actions_count: (model.sub_actions_count?.toString() ?? "0"),
          paid_actions_count: (model.paid_actions_count?.toString() ?? "0"),
				});
			}
		});

		// SORT: latest → oldest
		playerStory.sort((a, b) => {
			const gameA = BigInt(a.game_id.toString());
			const gameB = BigInt(b.game_id.toString());

			if (gameA !== gameB) {
				return gameA < gameB ? 1 : -1;
			}

			const lineA = BigInt(a.story_line.toString());
			const lineB = BigInt(b.story_line.toString());

			return lineA < lineB ? 1 : -1;
		});

    players = await queryPlayers();

	} catch (error) {
		console.error("Error fetching game ids from Torii:", error);
		throw error;
	}

	return [playerStory, players];
};

// Query all the Players
const queryPlayers = async (): Promise<Player[]> => {
  let players: Player[] = [];
	try {
    const { sdk } = await InitDojo();
    const query = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withEntityModels(["lore-Player"]);

    const result = await sdk.getEntities({ query });

    result.getItems().forEach((item) => {
      const model = item.models?.lore?.Player;

      if (
        model &&
        model.inst !== undefined &&
        model.is_player !== undefined &&
        model.location !== undefined &&
        model.use_debug !== undefined &&
        model.is_dead !== undefined &&
        model.address !== undefined &&
        model.game_id !== undefined
      ) {
        players.push({
          inst: model.inst,
          is_player: model.is_player,
          address: model.address,
          game_id: model.game_id,
          location: model.location,
          use_debug: model.use_debug,
          is_dead: model.is_dead,
        });
      }
    });
  } catch (error) {
    console.error("Error fetching Players from Torii:", error);
    throw error;
  }

  return players;
};

// Query all StoryLines of type error and the commands that caused them
const queryStorylinesErrorsCommands = async (sdk: SDK<SchemaType>): Promise<
  [StoryLine, StoryLine][]
> => {
  const pairs: [StoryLine, StoryLine][] = [];

  try {
    const query = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(9000)
      .includeHashedKeys()
      .withEntityModels(["lore-StoryLine"]);

    const result = await sdk.getEntities({ query });
    const items = result.getItems();

    // Step 1: Build lookup map (gameId-key → StoryLine model)
    const storyLineMap = new Map<string, typeof items[number]["models"]["lore"]["StoryLine"]>();

    items.forEach((entity) => {
      const model = entity.models?.lore?.StoryLine;
      if (model && model.game_id !== undefined && model.key !== undefined) {
        const mapKey = `${model.game_id.toString()}-${model.key.toString()}`;
        storyLineMap.set(mapKey, model);
      }
    });

    // Step 2: Loop once and match errors to their commands
    items.forEach((entity) => {
      const model = entity.models?.lore?.StoryLine;

      if (
        model &&
        model.game_id !== undefined &&
        model.key !== undefined &&
        model.line !== undefined &&
        model.location !== undefined &&
        model.line_type !== undefined &&
        model.line_type.toString() === "Error"
      ) {
        const gameIdStr = model.game_id.toString();
        const errorKey = BigInt(model.key.toString());
        const commandKey = errorKey - 1n;

        const lookupKey = `${gameIdStr}-${commandKey.toString()}`;
        const commandModel = storyLineMap.get(lookupKey);

        if (
          commandModel &&
          commandModel.game_id !== undefined &&
          commandModel.key !== undefined &&
          commandModel.line_type !== undefined &&
          commandModel.line_type.toString() === "Command" &&
          commandModel.line !== undefined &&
          commandModel.location !== undefined
        ) {
          const errorStoryLine: StoryLine = {
            game_id: model.game_id,
            key: model.key,
            line: model.line,
            line_type: model.line_type,
            location: model.location,
          };

          const commandStoryLine: StoryLine = {
            game_id: commandModel.game_id,
            key: commandModel.key,
            line: commandModel.line,
            line_type: commandModel.line_type,
            location: commandModel.location,
          };

          pairs.push([errorStoryLine, commandStoryLine]);
        }
      }
    });
  } catch (error) {
    console.error("Error fetching StoryLines from Torii:", error);
    throw error;
  }

  return pairs;
};

// Query all the trail_token_info::progress
const queryTrailProgress = async (sdk: SDK<SchemaType>, gameID: bigint, trailID: bigint): Promise<Partial<TrailProgress> | undefined> => {
  let trailProgress: Partial<TrailProgress> | undefined;
  try {
    const query = new ToriiQueryBuilder<SchemaType>()
      .withCursor("")
      .withLimit(1000)
      .includeHashedKeys()
      .withClause(
        new ClauseBuilder<SchemaType>().keys(
          ["lore-TrailProgress"],
          [bigintToHex128(gameID), bigintToHex128(trailID)]
        ).build()
      ).withEntityModels(["lore-TrailProgress"]);
    
    const result = await sdk.getEntities({ query });

    const item = result.getItems().at(0);
    const posTrailProgress = item?.models?.lore?.TrailProgress;
    
    if ( posTrailProgress &&
      posTrailProgress.game_id !== undefined &&
      posTrailProgress.trail_id !== undefined &&
      posTrailProgress.percentage !== undefined &&
      posTrailProgress.completed !== undefined
    ) {
      trailProgress = posTrailProgress;
      console.log("trailProgress for gameID:", gameID.toString(), "trailID:", trailID.toString(), ":", trailProgress);
    }
    
  } catch (error) {
    console.error("Error fetching trail progress from Torii:", error);
    throw error;
  }
  return trailProgress;
};

/**
 * 
 * Instead of firing all promises at once, it only runs up to limit promises in parallel.
 * This avoids:
 * Overloading the network (e.g., 1000 queryErrorLocation calls at once)
 * Excessive memory usage
 * Rate-limiting or throttling issues
 */
async function mapWithConcurrency<T, R>(
  items: T[],
  limit: number,
  asyncMapper: (item: T) => Promise<R>
): Promise<R[]> {
  const results: R[] = new Array(items.length);
  let currentIndex = 0;

  async function worker() {
    while (true) {
      const index = currentIndex++;
      if (index >= items.length) break;

      results[index] = await asyncMapper(items[index]);
    }
  }

  const workers = Array.from(
    { length: Math.min(limit, items.length) },
    () => worker()
  );

  await Promise.all(workers);
  return results;
}

// Helper: CSV Converter
function convertToCSV(rows: Record<string, any>[]): string {
  if (!rows.length) return "";

  const headers = Object.keys(rows[0]);

  const csv = [
    headers.join(","),
    ...rows.map((row) =>
      headers.map((field) => JSON.stringify(row[field] ?? "")).join(",")
    ),
  ].join("\n");

  return csv;
}