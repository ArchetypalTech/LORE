import { promises as fs } from "fs";
import { shortString, type BigNumberish } from "starknet";

export const getProfileEnv = async (profile: string, envName: string) => {
	const filePath = `./dojo_${profile}.toml`;

	try {
		const content = await fs.readFile(filePath, "utf-8");
		// Match `envName = "value"` or `envName = 'value'` or `envName = value`
		const regex = new RegExp(`^\\s*${envName}\\s*=\\s*(?:"([^"]+)"|'([^']+)'|([^\\s#]+))`, "m");
		const match = content.match(regex);
		if (match) {
			return match[1] || match[2] || match[3];
		}
		return null;
	} catch (error) {
		console.error(`Error reading or parsing ${filePath}:`, error);
		return null;
	}
};

export const runProcess = async (command: string, env: any = {}, ignoreError: boolean = false) => {
	console.log(`>> ${command}`);
	const cmd = command.split(" ");
	const proc = Bun.spawn(cmd, {
		env: { ...import.meta.env, ...env },
		onExit: async (proc, exitCode, signalCode, error) => {
			if (error || exitCode !== 0) {
				console.error(">>> runProcess() error:", error, exitCode);
				if (!ignoreError) {
					process.exit(exitCode);
				}
				throw error;
			}
		},
	});
	try {
		const output = await new Response(proc.stdout).text();
		console.log(output);
		await proc.exited;
		return output;
	} catch (error) {
		return undefined;
	}
};

export const stringToFelt = (v: string): BigNumberish => (v ? shortString.encodeShortString(v) : '0x0')

export async function fileExistsAsync(path: string): Promise<boolean> {
  try {
    await fs.access(path, fs.constants.F_OK);
    return true;
  } catch (e) {
    return false;
  }
}
