import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Site — gotta.cc",
  description: "A curated, AI-scored site in the gotta.cc directory.",
};

export default function SiteLayout({ children }: { children: React.ReactNode }) {
  return children;
}
