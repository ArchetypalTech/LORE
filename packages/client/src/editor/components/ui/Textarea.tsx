import * as React from "react";
import { cn } from "@/lib/utils/utils";

const Textarea = React.forwardRef<
	HTMLTextAreaElement,
	React.ComponentProps<"textarea">
>(({ className, style, onChange, ...props }, ref) => {
	const internalRef = React.useRef<HTMLTextAreaElement>(null);

  // Combine forwarded ref and internalRef
  React.useImperativeHandle(ref, () => internalRef.current!);

  const adjustHeight = (el: HTMLTextAreaElement) => {
    el.style.height = "auto"; // Reset height so scrollHeight is accurate
    el.style.height = `${el.scrollHeight}px`; // Set height to fit content
  };

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    adjustHeight(e.target);
    if (onChange) onChange(e);
  };

  // On mount, adjust height based on initial content
  React.useEffect(() => {
    if (internalRef.current) {
      adjustHeight(internalRef.current);
    }
  }, []);

	return (
		<textarea
			className={cn(
				"flex min-h-[60px] w-full rounded-md border border-input border-dashed px-2 py-2 text-base shadow-xs placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 md:text-sm ",
				className,
			)}
			ref={internalRef}
      onChange={handleChange}
      style={{ ...style, overflow: "hidden", resize: "none" }}
			{...props}
		/>
	);
});
Textarea.displayName = "Textarea";

export { Textarea };
