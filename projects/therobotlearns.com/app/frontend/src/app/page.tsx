import type { Metadata } from "next";
import { Landing } from "@/components/landing/landing";

export const metadata: Metadata = {
  title: "The Robot Learns | AI learning workspace",
  description:
    "The Robot Learns is a cloud workspace for durable knowledge, adaptive study plans, quizzes, and MCP-assisted learning content.",
};

export default function Home() {
  return <Landing />;
}
