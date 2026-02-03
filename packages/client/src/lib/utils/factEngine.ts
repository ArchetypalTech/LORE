import { INTERESTING_FACTS } from "./facts";
import {
	addTerminalContent,
} from "@lib/stores/terminal.store";

let pool: string[] = [];
let index = 0;

const shuffle = (arr: string[]) => {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
};

export const nextFact = (): string => {
  if (pool.length === 0 || index >= pool.length) {
    pool = shuffle([...INTERESTING_FACTS]);
    index = 0;
  }
  return pool[index++];
};

export const sleep = (ms: number) => new Promise(res => setTimeout(res, ms));

export const startFetchingAmbientMessages = () => {
  let running = true;

  const loop = async () => {
    while (running) {
      // t = 0s → Fact
      addTerminalContent({
        text: `💡 ${nextFact()}`,
        format: "system",
        useTypewriter: true,
      });

      // wait 10s
      await sleep(10_000);
      if (!running) break;

      // t = 10s → Still fetching
      addTerminalContent({
        text: "STILL FETCHING GAME DATA...",
        format: "system",
        useTypewriter: true,
      });

      // wait remaining 20s to complete 30s cycle
      await sleep(20_000);
    }
  };

  loop();

  // stop function
  return () => {
    running = false;
  };
};