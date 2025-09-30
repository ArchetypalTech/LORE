import { useRef, useEffect } from 'react';
import audioTrack from '../../assets/The-Belly-Of-The-Earth-Instrumental.mp4'
import { useTerminalStore } from '@/lib/stores/terminal.store';
import { useDojoStore } from '@/lib/stores/dojo.store';

export default function() {
  const audioRef = useRef<HTMLAudioElement>(null);
    const {
      status: { status },
    } = useDojoStore();
    const {enableAudio} = useTerminalStore()
  const handleCanPlay = () => {
    if(audioRef.current) audioRef.current.volume = 0.5;
  }
  // play when player can input
  useEffect(() => {
    if(status === 'inputEnabled' && audioRef.current && enableAudio) {
      audioRef.current.play();
    }
  }, [status, enableAudio])

  return (
    <audio
      ref={audioRef}
      src={audioTrack}
      muted={!useTerminalStore().enableAudio}
      onCanPlay={handleCanPlay}
      loop={true}
      style={{ visibility: "hidden" }}
    />
  );
}