import { useEffect, useRef, useState } from "react";
import { useDojoStore } from "@/lib/stores/dojo.store";
import { useTerminalStore } from "@/lib/stores/terminal.store";

// Tracks link
const tracks = [
	"https://docs.google.com/uc?export=download&id=1tDIy7xg6GdHTm-foUHd5GjuZSB7kv3zf", // I'm your Guy (instrumental)
	"https://docs.google.com/uc?export=download&id=1SSeTiUGTDFfbVoFWoFzWpRtMiEkWtUmr", // The Belly of the Earth (instrumental)
	"https://docs.google.com/uc?export=download&id=186mTlgYxVfhmxYSNA9wIAo_RjmJTAqHv", // Without saying a thing (instrumental)
	"https://docs.google.com/uc?export=download&id=1c57tzTNHxIlM1X_5wpt14otWUKGdSRES", // You're Home (instrumental)
];

// Random track generator avoiding immediate repeats
function randomTrack(currentTrack: string) {
  const otherTracks = tracks.filter(track => track !== currentTrack);
  return otherTracks[Math.floor(Math.random() * otherTracks.length)];
}

export default function () {
	// start with random track
	//const [useTrack, setTrack] = useState(randomTrack());
	// Start with "The Belly of the Earth"
  const [useTrack, setTrack] = useState(
    "https://docs.google.com/uc?export=download&id=1SSeTiUGTDFfbVoFWoFzWpRtMiEkWtUmr"
  );
	// to know when to start randoms tracks
  const [hasPlayedIntro, setHasPlayedIntro] = useState(false); 
  const audioRef = useRef<HTMLAudioElement>(null);

	const {
		status: { status },
	} = useDojoStore();
	const { enableAudio, volumeAudio } = useTerminalStore();

	// Handle loaded metadata to set start time every time it plays
  const handleLoadedMetadata = () => {
    if (
      useTrack ===
        "https://docs.google.com/uc?export=download&id=1SSeTiUGTDFfbVoFWoFzWpRtMiEkWtUmr" &&
      audioRef.current
    ) {
      audioRef.current.currentTime = 65; // start at 1:05
      audioRef.current.play();
    }
  };

	// Handle can play for normal tracks
  const handleCanPlay = () => {
    if (audioRef.current && enableAudio) {
      audioRef.current.volume = volumeAudio;
      // Play normally if not “The Belly of the Earth”
      if (useTrack !== "https://docs.google.com/uc?export=download&id=1SSeTiUGTDFfbVoFWoFzWpRtMiEkWtUmr") {
        audioRef.current.play();
      }
    }
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

	const handleEnded = () => {
    setTrack(prev => {
      if (!hasPlayedIntro) setHasPlayedIntro(true);
      return randomTrack(prev); // pick a random track avoiding immediate repeat
    });
  };

	return (
		<audio
      ref={audioRef}
      src={useTrack}
      muted={!enableAudio}
      onEnded={handleEnded}
      onLoadedMetadata={handleLoadedMetadata}
      onCanPlay={handleCanPlay}
      style={{ visibility: "hidden" }}
    />
	);
}
