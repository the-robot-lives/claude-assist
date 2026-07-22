import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Category — gotta.cc",
  description: "Browse sites in this category of the gotta.cc directory.",
};

export default function CategoryLayout({ children }: { children: React.ReactNode }) {
  return children;
}
