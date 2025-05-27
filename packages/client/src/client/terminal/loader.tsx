import { useEffect, useState } from "react";

export default function LoadingMessage() {

  const animation = ['⠙', '⠘', '⠰', '⠴', '⠤', '⠦', '⠆', '⠃', '⠋', '⠉']
  let [tick, setTick] = useState(0)
  useEffect(() => {
    let interval = setInterval(() => setTick(() => tick++), 100);
    return () => clearInterval(interval)
  }, [])
  return (
    <div className="event-loader text-2xl">
      <span>{animation[tick % animation.length]}</span>
    </div>  
  )
}
