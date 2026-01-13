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
    const [playerStories, players] = await queryPlayerStories();

    // game_id -> player address
    const gameToPlayer: Record<string, string> = {};
    players.forEach((p) => {
      gameToPlayer[p.game_id.toString()] = p.address;
    });

    /**
     * Final structure:
     * {
     *   [playerAddress]: {
     *     [gameId]: {
     *       latest_story_line,
     *       storylines: StoryLine[]
     *     }
     *   }
     * }
     */
    const grouped: Record<
      string,
      Record<string, { latest_story_line: bigint; storylines: StoryLine[] }>
    > = {};

    // IMPORTANT: for...of so we can await
    for (const story of playerStories) {
      console.log(`[QUERY] story: ${story}`);
      const gameId = BigInt(story.game_id.toString());
      const latestKey = BigInt(story.story_line.toString());
      const gameIdStr = gameId.toString();
      console.log(`[QUERY] gameId=${gameId} latestKey=${latestKey}`);

      const playerAddress = gameToPlayer[gameIdStr];
      if (!playerAddress) continue;

      // Fetch all storylines for this game
      const storylines = await queryStorylines(gameId, latestKey);

      if (!grouped[playerAddress]) {
        grouped[playerAddress] = {};
      }

      grouped[playerAddress][gameIdStr] = {
        latest_story_line: latestKey,
        storylines,
      };
    }

    // ---- Export JSON ----
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

// Query all the StoryLines for a given gameId
const queryStorylines = async (gameId: bigint,latestKey: bigint): Promise<StoryLine[]> => {
  // console.log(`[QUERY] Fetching StoryLines for gameId=${gameId} latestKey=${latestKey}`);
  const storylines: StoryLine[] = [];

  const { sdk } = await InitDojo();
  // Loop backwards: latest → oldest
  for (let key = latestKey; key >= 1n; key--) {
    try {
      const query_storyline = new ToriiQueryBuilder<SchemaType>()
        .withCursor("")
        .withLimit(1000)
        .includeHashedKeys()
        .withClause(
          new ClauseBuilder<SchemaType>()
            .keys(
              ["lore-StoryLine"],
              [bigintToHex128(gameId), bigintToAddress(key)]
            )
            .build()
        )
        .withEntityModels(["lore-StoryLine"]);

      const result_storyline = await sdk.getEntities({
        query: query_storyline,
      });
      // console.log(`[QUERY] Fetching StoryLines for gameId=${gameId} key=${key} result=${result_storyline}`);
      result_storyline.getItems().forEach((entity) => {
        const model = entity.models?.lore?.StoryLine;
        if (
          model &&
          model.game_id !== undefined &&
          model.key !== undefined &&
          model.line !== undefined
        ) {
          storylines.push({
            game_id: model.game_id,
            key: model.key,
            line: model.line,
            line_type: model.line_type as CairoCustomEnum,
          });
        }
      });
    } catch (error) {
      console.error(
        `Error fetching StoryLine for gameId=${gameId} key=${key}:`,
        error
      );
      // continue to next key
    }
  }

  // No sort needed — already latest → oldest
  return storylines;
};