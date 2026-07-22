import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Search — gotta.cc",
  description: "Search the gotta.cc directory of curated, AI-scored websites.",
};

export default function SearchLayout({ children }: { children: React.ReactNode }) {
  return children;
}
