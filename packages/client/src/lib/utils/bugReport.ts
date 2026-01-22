export const reportBug = () => {
  if (typeof window === "undefined") return;

  window.open(
    "https://docs.google.com/forms/d/e/1FAIpQLScwikBSH7w5Pym1n--4f9ShgXoi3m7rPICanMhU5vdbUsGnKA/viewform?usp=dialog",
    "_blank",
    "noopener,noreferrer"
  );
};