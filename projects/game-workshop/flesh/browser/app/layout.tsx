import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Flesh Backlog Browser",
  description: "Search and grade browser for game-workshop flesh backlog concepts."
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
