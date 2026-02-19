import { InitDojo } from "../dojo";
import { ToriiQueryBuilder } from "@dojoengine/sdk";
import { SchemaType, Player, PlayerStory, StoryLine } from "@/lib/dojo_bindings/typescript/models.gen";
import { ClauseBuilder } from "@dojoengine/sdk";
import { bigintToAddress, bigintToHex128 } from "@/lib/utils/utils";
import { CairoCustomEnum } from "starknet";
import JSONbig from "json-bigint";


// Call queries and generate json file
export const queryStories = async (): Promise<void> => {
  try {
    // Query all the PlayerStories and Players
    const [playerStories, players] = await queryPlayerStories();

    // Query all StoryLines of type error and the commands that caused them
    const errorCommandPairs = await queryStorylinesErrorsCommands();
    console.log(`[QUERY] Found ${errorCommandPairs.length} error-command pairs`);

    console.log("DEBUG: starting to sort");
    // Flatten pairs into a single StoryLine[]
    const allStorylinesErrors: StoryLine[] = [];
    errorCommandPairs.forEach(([error, command]) => {
      allStorylinesErrors.push(error);
      allStorylinesErrors.push(command);
    });

    // -------------------------------
    // game_id -> player address
    // -------------------------------
    const gameToPlayer: Record<string, string> = {};
    players.forEach((p) => {
      gameToPlayer[p.game_id.toString()] = p.address;
    });

    // -------------------------------
    // game_id -> latest_story_line
    // -------------------------------
    const latestByGame: Record<string, bigint> = {};
    playerStories.forEach((ps) => {
      latestByGame[ps.game_id.toString()] = BigInt(ps.story_line.toString());
    });

    // -------------------------------
    // game_id -> StoryLine[]
    // -------------------------------
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

    /**
     * Final structure:
     * {
     *   [playerAddress]: {
     *     [gameId]: {
     *       latest_story_line,
     *       storylines
     *     }
     *   }
     * }
     */
    const grouped: Record<
      string,
      Record<string, { latest_story_line: bigint; storylines: StoryLine[] }>
    > = {};

    for (const gameIdStr of Object.keys(latestByGame)) {
      const playerAddress = gameToPlayer[gameIdStr];
      if (!playerAddress) continue;

      if (!grouped[playerAddress]) {
        grouped[playerAddress] = {};
      }

      grouped[playerAddress][gameIdStr] = {
        latest_story_line: latestByGame[gameIdStr],
        storylines: storylinesByGame[gameIdStr] ?? [],
      };
    }

    // -------------------------------
    // Export JSON
    // -------------------------------
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

    console.log("DEBUG: finished sorting");
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