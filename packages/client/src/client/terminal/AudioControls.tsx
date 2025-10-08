import { useTerminalStore, toggleMuted, increaseVolume, decreaseVolume } from "@/lib/stores/terminal.store";
import SVG from "./SVGWrap"
import { useEffect, useState } from "react";

export default function() {
  const { enableAudio, volumeAudio } = useTerminalStore();
  const [volume, setVolume] = useState("")

  useEffect(() => {
    if(!enableAudio) return setVolume("")
    setVolume(`${ Math.round(volumeAudio * 100)}`)
  console.log(volume)
  }, [volumeAudio])

  return (
    <div className='flex flex-col gap-2 text-amber-300'>
      <button onClick={() => increaseVolume()} className="text-left text-xs cursor-pointer"><SVG><use href="/sprites.svg#icon-volume-2"></use></SVG></button>
      <button onClick={() => decreaseVolume()} className="text-left text-xs cursor-pointer"><SVG><use href="/sprites.svg#icon-volume-1"></use></SVG></button>
      <button onClick={() => toggleMuted()} className="flex gap-2 items-center text-left text-xs cursor-pointer">
        <SVG><use href={`/sprites.svg#${enableAudio ? "icon-volume" : "icon-volume-x"}`}></use></SVG>
        <span>background music {volume}</span>
      </button>
    </div>
  );
}