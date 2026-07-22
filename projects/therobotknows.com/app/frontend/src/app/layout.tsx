import type { Metadata } from "next";
import { Lora, Source_Serif_4, Inter, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const lora = Lora({
  variable: "--font-lora",
  subsets: ["latin"],
  weight: ["400", "600", "700"],
  style: ["normal", "italic"],
});

const sourceSerif = Source_Serif_4({
  variable: "--font-source-serif",
  subsets: ["latin"],
  weight: ["400", "600", "700"],
  style: ["normal", "italic"],
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains",
  subsets: ["latin"],
  weight: ["400", "500"],
});

export const metadata: Metadata = {
  title: "TheRobotKnows — Consistent creative knowledge graphs",
  description:
    "A living wiki for novels, campaigns, and game lore. Define canon, generate with citations, and catch contradictions. Free beta.",
  openGraph: {
    title: "TheRobotKnows — Consistent creative knowledge graphs",
    description:
      "Canon, generation, consistency, and graph for creative universes. Free beta — invite for email signup; Authentik SSO welcome.",
    siteName: "therobotknows.com",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <link rel="icon" href="/favicon.svg" type="image/svg+xml" />
      </head>
      <body
        className={`${lora.variable} ${sourceSerif.variable} ${inter.variable} ${jetbrainsMono.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
