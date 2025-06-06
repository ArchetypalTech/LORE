export type DojoStatus = {
	status: "initialized" | "loading" | "error" | "inputEnabled";
	error: string | null;
};
