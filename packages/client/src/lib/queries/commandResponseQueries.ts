import { InitDojo } from "../dojo";
import { ToriiQueryBuilder } from "@dojoengine/sdk";
import { SchemaType, Player, PlayerStory, StoryLine } from "@/lib/dojo_bindings/typescript/models.gen";
import { fromWei, queryErrorLocation } from "../queriesPanel/uiPanelQueries";
import JSONbig from "json-bigint";


// Call queries and generate json file
export const queryStories = async (): Promise<void> => {
  try {
    // ---------------------------------
    // 1 Query PlayerStories & Players
    // ---------------------------------
    const [playerStories, players] = await queryPlayerStories();

    // ---------------------------------
    // 2 Query Error + Command pairs
    // ---------------------------------
    const errorCommandPairs = await queryStorylinesErrorsCommands();

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

    // Sort each game's storylines latest → oldest
    Object.values(storylinesByGame).forEach((lines) => {
      lines.sort((a, b) =>
        BigInt(a.key.toString()) < BigInt(b.key.toString()) ? 1 : -1
      );
    });

    // ---------------------------------
    // 5 game_id -> player address
    // ---------------------------------
    const gameToPlayer: Record<string, string> = {};
    players.forEach((p) => {
      gameToPlayer[p.game_id.toString()] = p.address;
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
          storylines: (StoryLine & { locationName?: string })[];
        }
      >
    > = {};

    for (const gameIdStr of Object.keys(playerStoryByGame)) {
    const playerAddress = gameToPlayer[gameIdStr];
    if (!playerAddress) continue;

    const ps = playerStoryByGame[gameIdStr];

    const player = players.find(
      (p) => p.game_id.toString() === gameIdStr
    );
    if (!player) continue;

    if (!grouped[playerAddress]) {
      grouped[playerAddress] = {};
    }

    // const enrichedStorylines = await Promise.all(
    //   (storylinesByGame[gameIdStr] ?? []).map(async (line) => {
    //     let locationName = "";

    //     try {
    //       const locationEntity = await queryErrorLocation(
    //         BigInt(line.game_id.toString()),
    //         BigInt(player.inst.toString()),
    //         BigInt(line.location.toString())
    //       );

    //       locationName = locationEntity?.name?.toString() ?? "";
    //     } catch (e) {
    //       console.error("Error resolving location for storyline:", e);
    //     }

    //     return {
    //       ...line,
    //       locationName,
    //     };
    //   })
    // );

    const enrichedStorylines = await mapWithConcurrency(
      storylinesByGame[gameIdStr] ?? [],
      8, // safe limit for 1000+ storylines
      async (line) => {
        const locationEntity = await queryErrorLocation(
          BigInt(line.game_id.toString()),
          BigInt(player.inst.toString()),
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
      storylines: enrichedStorylines,
    };
  }

    // ---------------------------------
    // 8 Export JSON
    // ---------------------------------
    const formatter = new Intl.DateTimeFormat("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });

    const filename = `player_data_${formatter
      .format(new Date())
      .replace(/ /g, "_")}.json`;

    const json = JSONbig.stringify(grouped, null, 2);
    const blob = new Blob([json], { type: "application/json" });
    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    a.click();

    URL.revokeObjectURL(url);
  } catch (error) {
    console.error("Error querying or exporting grouped PlayerStories:", error);
    throw error;
  }
};

// Query all the PlayerStory
const queryPlayerStories = async (): Promise<[(PlayerStory[]), Player[]]> => {
	let playerStory: PlayerStory[] = [];
  let players: Player[] = [];

	try {
		const { sdk } = await InitDojo();

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
const queryStorylinesErrorsCommands = async (): Promise<
  [StoryLine, StoryLine][]
> => {
  const pairs: [StoryLine, StoryLine][] = [];

  const { sdk } = await InitDojo();

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