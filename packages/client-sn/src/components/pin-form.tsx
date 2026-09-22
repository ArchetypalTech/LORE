import {
	type FormEvent,
	type KeyboardEvent,
	useEffect,
	useRef,
	useState,
} from "react";
import { Logo } from "@/components/logo";
import { checkPin } from "@/lib/pin";

const DIGITS = 4;
const NON_ADVANCING_KEYS = [
	"Tab",
	"Backspace",
	"Shift",
	"Meta",
	"Alt",
	"Control",
];

/** 4-box PIN entry; each box auto-advances to the next, then to submit. Calls `onUnlock` on a correct PIN. */
export function PinForm({ onUnlock }: { onUnlock: () => void }) {
	const [values, setValues] = useState<string[]>(Array(DIGITS).fill(""));
	const [error, setError] = useState(false);
	const inputs = useRef<(HTMLInputElement | null)[]>([]);
	const submit = useRef<HTMLButtonElement>(null);

	useEffect(() => inputs.current[0]?.focus(), []);

	const handleKeyUp =
		(index: number) => (e: KeyboardEvent<HTMLInputElement>) => {
			setError(false);
			if (NON_ADVANCING_KEYS.includes(e.key)) return;
			(inputs.current[index + 1] ?? submit.current)?.focus();
		};

	const handleSubmitKeyDown = (e: KeyboardEvent<HTMLButtonElement>) => {
		if (e.key !== "Tab") return;
		e.preventDefault();
		inputs.current[0]?.focus();
	};

	const handleSubmit = async (e: FormEvent) => {
		e.preventDefault();
		if (await checkPin(values.join(""))) onUnlock();
		else setError(true);
	};

	return (
		<form
			onSubmit={handleSubmit}
			className="flex flex-col items-center justify-center gap-8 rounded-lg border-[0.025em] border-black bg-primary p-16 text-black shadow-lg"
		>
			<Logo className="size-[1.5em] text-3xl" />
			<h2 className="text-base">Enter PIN</h2>
			<div className="flex justify-center gap-4">
				{values.map((value, index) => (
					<input
						key={index}
						ref={(el) => {
							inputs.current[index] = el;
						}}
						value={value}
						onChange={(e) =>
							setValues((prev) =>
								prev.map((v, i) => (i === index ? e.target.value : v)),
							)
						}
						onKeyUp={handleKeyUp(index)}
						maxLength={1}
						type="text"
						className="w-[1em] min-w-[1.125em] rounded-md border-[0.025em] border-black bg-white text-center text-[3em] text-black"
					/>
				))}
			</div>
			{error && <span className="text-red-700 text-xs">incorrect challenge</span>}
			<button
				ref={submit}
				type="submit"
				onKeyDown={handleSubmitKeyDown}
				className="rounded-md border-[0.075em] border-black bg-[aliceblue] px-[1em] py-[0.5em] hover:bg-white"
			>
				submit
			</button>
		</form>
	);
}
