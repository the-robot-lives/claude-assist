import { Socket, Channel } from "phoenix";
import { getRuntimeConfig } from "./runtime-config";

let socket: Socket | null = null;

// ⟦𓊼𓆝𓈟𓈊⟧ getSocket :: auto-generated pointer for public function getSocket
export function getSocket(): Socket {
  if (socket) return socket;

  const config = getRuntimeConfig();
  const apiUrl = config.API_URL || "";
  const wsProtocol = apiUrl.startsWith("https") ? "wss" : "ws";
  const wsUrl = apiUrl.replace(/^https?/, wsProtocol);

  const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null;

  socket = new Socket(`${wsUrl}/socket`, {
    params: { token: token || "" },
  });

  socket.connect();
  return socket;
}

// ⟦𓂜𓁿𓌸𓁞⟧ joinChannel :: auto-generated pointer for public function joinChannel
export function joinChannel(topic: string, params = {}): Channel {
  const s = getSocket();
  const channel = s.channel(topic, params);
  channel.join();
  return channel;
}

// ⟦𓎙𓍊𓇗𓐪⟧ disconnectSocket :: auto-generated pointer for public function disconnectSocket
export function disconnectSocket() {
  if (socket) {
    socket.disconnect();
    socket = null;
  }
}
