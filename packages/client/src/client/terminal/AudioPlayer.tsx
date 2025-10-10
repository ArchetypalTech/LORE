import { useEffect, useRef, useState } from "react";
import { useDojoStore } from "@/lib/stores/dojo.store";
import { useTerminalStore } from "@/lib/stores/terminal.store";

// Tracks link - NOT IN USE CURRENTLY
// const tracks = [
// 	//"https://docs.google.com/uc?export=download&id=1tDIy7xg6GdHTm-foUHd5GjuZSB7kv3zf", // I'm your Guy (instrumental)
// 	"https://drive.google.com/file/d/1tDIy7xg6GdHTm-foUHd5GjuZSB7kv3zf/view",
// 	//"https://docs.google.com/uc?export=download&id=1SSeTiUGTDFfbVoFWoFzWpRtMiEkWtUmr", // The Belly of the Earth (instrumental)
// 	"https://drive.google.com/file/d1SSeTiUGTDFfbVoFWoFzWpRtMiEkWtUmr/view",
// 	//"https://docs.google.com/uc?export=download&id=186mTlgYxVfhmxYSNA9wIAo_RjmJTAqHv", // Without saying a thing (instrumental)
// 	"https://drive.google.com/file/186mTlgYxVfhmxYSNA9wIAo_RjmJTAqHv/view",
// 	//"https://docs.google.com/uc?export=download&id=1c57tzTNHxIlM1X_5wpt14otWUKGdSRES", // You're Home (instrumental)
// 	"https://drive.google.com/file/1c57tzTNHxIlM1X_5wpt14otWUKGdSRES/view",
// ];

// // Random track generator avoiding immediate repeats
// function randomTrack(currentTrack: string) {
//   const otherTracks = tracks.filter(track => track !== currentTrack);
//   return otherTracks[Math.floor(Math.random() * otherTracks.length)];
// }

const tracks = ["track_2", "track_3", "track_4", "track_5"];

function randomTrack(currentTrack: string) {
  if (tracks.length <= 1) return tracks[0]; // only one track, nothing to randomize
  let nextTrack;
  do {
    nextTrack = tracks[Math.floor(Math.random() * tracks.length)];
  } while (nextTrack === currentTrack); // loop until different track
  return `/album/${nextTrack}.mp3`;
}


export default function () {
	// start with random track
	//const [useTrack, setTrack] = useState(randomTrack());
	// Start with "The Belly of the Earth"
  const [useTrack, setTrack] = useState(
    "/album/track_3.mp3"
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
        "/album/track_3.mp3" &&
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
      if (useTrack !== "/album/track_3.mp3") {
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
      return randomTrack(prev); // random track, guaranteed not same as prev
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
