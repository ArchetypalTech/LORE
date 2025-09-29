import { useEffect, useState } from "react";

export default function() {
  const binary = [
			"010010",
      "001100",
      "100101",
      "111010",
      "111101",
      "010111",
			"101011",
			"111000",
			"110011",
			"110101"
		]
  const spinner = ["▌","▀", "▐","▄"]
  let [tick, setTick] = useState(0)
  useEffect(() => {
    let interval = setInterval(() => setTick((prev) => prev += 1), 200);
    return () => clearInterval(interval)
  }, [])
  return (
    <div className="flex justify-between items-center flex-col gap-2">
      <small>status: initialised</small>
    <div className="event-loader flex gap-4 text-3xl">
      <span>{binary[tick % binary.length]}</span>
      <span>{spinner[tick % spinner.length]}</span>
    </div>  
      <small>game loading</small>
    </div>
  )
}
