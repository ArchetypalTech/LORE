import { getPlayerAddress } from "../../editor/lib/components";
import { InitDojo } from "../dojo";
import { ToriiQueryBuilder } from "@dojoengine/sdk";
import { SchemaType, Player, PlayerStory, StoryLine, StoryLineType } from "@/lib/dojo_bindings/typescript/models.gen";
import { ClauseBuilder } from "@dojoengine/sdk";
import { bigintToAddress, bigintToHex128 } from "@/lib/utils/utils";
import { CairoCustomEnum, BigNumberish } from "starknet";
import JSONbig from "json-bigint";


// Call queries and generate json file
export const queryStories = async (): Promise<void> => {
	try {
		const stories = await queryPlayerStories();

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

		// BigInt-safe stringify
		const json = JSONbig.stringify(stories, null, 2);

		const blob = new Blob([json], { type: "application/json" });
		const url = URL.createObjectURL(blob);

		const a = document.createElement("a");
		a.href = url;
		a.download = filename;
		a.click();

		URL.revokeObjectURL(url);

	} catch (error) {
		console.error("Error querying or exporting PlayerStories:", error);
		throw error;
	}
};

// Query all the PlayerStory
const queryPlayerStories = async (): Promise<PlayerStory[]> => {
	let playerStory: PlayerStory[] = [];

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

	} catch (error) {
		console.error("Error fetching game ids from Torii:", error);
		throw error;
	}

	return playerStory;
};