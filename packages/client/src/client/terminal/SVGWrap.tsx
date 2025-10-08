import { ReactNode } from "react";
export default function ({ children }: { children: ReactNode }) {
	return (
		<svg
			width="1em"
			height="1em"
			fill="none"
			stroke="gold"
			strokeWidth="2"
			strokeLinecap="round"
			strokeLinejoin="round"
		>
			<title>volume-controls</title>
			{children}
		</svg>
	);
}
