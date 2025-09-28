 interface HelpContent {
	description: string;
	usage?: string;
	examples?: string[];
	more?: string;
}

export const HELP_TEXTS: Record<string, HelpContent> = {
	CommandSummary: {
		description:
			"\n\n a few possibilities surface through the haze of your mind\n\n",
		usage: ">look [around]\n >look at [object]\n >examine [object]\n >pick up [object]\n >use [object] on [target]\n >use [exit]\n >go through [exit]\n >coins_balance \n >check inventory \n\n TIP: The parser can only handle single word objects currently, so look for and only use the CAPITALISED words to send commands to e.g ferry OFFICER : >talk to officer etc",
		examples: [
			"look around",
			"enter the door",
			"examine the bottle \n\n ",
		],
		more: "Use:\n\n  `help_exits`\n  `help_inspect`\n  `help_container`\n & \n  `help_inventory` \n\nfor more information",
	},
// Exits: {
// 	description:
// 		"Move through the world using objects or going in a specific direction",
// 	usage: "go [direction], enter [exit], use [exit]",
// 	examples: [
// 		"go north",
// 		"enter the door",
// 		"use teleport",
// 	],
// 	more: "Use:\n  `help_exits for more information",
// },
// Reactables: {
// 	description: "Examine your surroundings or specific objects",
// 	usage: "look [around], look at [object], examine [object]",
// 	examples: ["look", "look around", "look at tree"],
// 	more: "Use `help_inspect` for more information",
// },
// Containers: {
// 	description: "Store inventory items inside them",
// 	usage: "open [object], close [object], check [object]",
// 	examples: ["open the bag", "close the bag", "check the bag"],
// 	more: "Use `help_container` for more information",
// },
// InventoryItems: {
// 	description: "Objects that can be placed in containers and used",
// 	usage: "pickup [object], drop [object], use [object] on [target]",
// 	examples: ["pickup the key", "drop the key", "use the key on the door"],
// 	more: "Use `help_inventory` for more information",
// },
};

export const HELP_INSPECT: Record<string, HelpContent> = {
	look:{
		description: "Examine your surroundings or specific objects",
		usage: "look [around], look at [object]",
		examples: ["look", "look around", "look at tree"],
	},
	examine: {
		description: "Examine specific objects, gives more information",
		usage: "examine [object]",
		examples: ["examine the bag"],
	},
	check: {
		description: "Examine the object further more, gives more information",
		usage: "check [object]",
		examples: ["check the bag", "check the door"],
	},
	other: {
		description: "Gives more information about the object",
		usage: "smell [object], taste [object], touch [object]",
		examples: ["smell the bag", "touch the door"],
	},

};
export const HELP_EXITS: Record<string, HelpContent> = {
	go: {
		description:
			"Move through the world in a specific direction\n can also just use direction",
		usage: "go [direction]",
		examples: [
			"go north",
			"go south",
			"go east",
			"go west",
			"go up",
			"go down",
			"go n",
			"go s",
			"go ...",
		],
	},
	enter: {
		description: "Enter a specific exit",
		usage: "enter [exit]",
		examples: ["enter the door", "enter teleport"],
	},
	use: {
		description: "Use a specific exit",
		usage: "use [exit]",
		examples: ["use the door", "use teleport"],
	},
};
export const HELP_CONTAINER: Record<string, HelpContent> = {
	open: {
		description: "Opens a specific container",
		usage: "open [container]",
		examples: ["open the bag", "open the box"],
	},
	close: {
		description: "Closes a specific container",
		usage: "close [container]",
		examples: ["close the bag", "close the box"],
	},
	check: {
		description: "Checks a specific container and gives information",
		usage: "check [container]",
		examples: ["check the bag", "check the box"],
	},
	inventory: {
		description: "Checks your personal inventory inventory",
		usage: "inventory",
	},
};
export const HELP_INVENTORY: Record<string, HelpContent> = {
	pickup: {
		description: "Picks up an object and places it in your personal inventory",
		usage: "pickup [object]",
		examples: ["pickup paper", "pickup the key"],
	},
	drop: {
		description: "Drops an object from your personal inventory",
		usage: "drop [object]",
		examples: ["drop paper", "drop the key"],
	},
	take: {
		description: "Takes an object from a specific container and places in the ground",
		usage: "take [object] from [container]",
		examples: ["take paper from the bag", "take the key from the box"],
	},
	put: {
		description: "Puts an object in a specific container",
		usage: "put [object] in [container]",
		examples: ["put paper in the bag", "put the key in the box"],
	},
	use: {
		description: "Uses an object on a specific target",
		usage: "use [object] on [target]",
		examples: ["use the key on the door"],
	},
	other: {
		description: "Further usage of objects",
		usage: "show [object] to [target], read [object] to [target]",
		examples: ["show the id to the officer", "read the book to the child"],
	},
};
