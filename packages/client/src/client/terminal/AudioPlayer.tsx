import { useEffect, useRef, useState } from "react";
import { useDojoStore } from "@/lib/stores/dojo.store";
import { useTerminalStore } from "@/lib/stores/terminal.store";

function randomTrack() {
	const collection = ["track_1", "track_2", "track_3", "track_4", "track_5"];
	const trackname = collection[Math.floor(Math.random() * collection.length)];
	return `/album/${trackname}.mp3`;
}

export default function () {
	const [useTrack, setTrack] = useState(randomTrack());
	const audioRef = useRef<HTMLAudioElement>(null);
	const {
		status: { status },
	} = useDojoStore();
	const { enableAudio, volumeAudio } = useTerminalStore();
	const handleCanPlay = () => {
		if (audioRef.current) audioRef.current.volume = volumeAudio;
	};
	// handle volume
	useEffect(() => {
		if (audioRef.current) audioRef.current.volume = volumeAudio;
	}, [volumeAudio]);
	// play when player can input
	useEffect(() => {
		if (status === "inputEnabled" && audioRef.current && enableAudio) {
			audioRef.current.play();
		}
	}, [status, enableAudio]);

	return (
		<audio
			ref={audioRef}
			src={useTrack}
			muted={!useTerminalStore().enableAudio}
			onEnded={() => setTrack(randomTrack())}
			loop={true}
			onCanPlay={handleCanPlay}
			style={{ visibility: "hidden" }}
		/>
	);
}
