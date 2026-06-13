import type { Metadata } from "next";
import { IBM_Plex_Mono, Barlow_Condensed, Barlow } from "next/font/google";
import "./globals.css";

const ibmPlexMono = IBM_Plex_Mono({
  variable: "--font-ibm-plex-mono",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
  style: ["normal", "italic"],
});

const barlowCondensed = Barlow_Condensed({
  variable: "--font-barlow-condensed",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
});

const barlow = Barlow({
  variable: "--font-barlow",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
});

export const metadata: Metadata = {
  title: "TheRobotMakes — From Pitch to Product and Beyond",
  description:
    "Robot-assisted product development. You steer. The robots build.",
  openGraph: {
    title: "TheRobotMakes — From Pitch to Product and Beyond",
    description: "You steer. The robots build.",
    url: "https://therobotmakes.com",
    siteName: "TheRobotMakes",
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
      <body
        className={`${ibmPlexMono.variable} ${barlowCondensed.variable} ${barlow.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
