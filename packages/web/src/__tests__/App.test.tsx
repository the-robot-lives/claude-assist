import { describe, test, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { App } from "../App.tsx";

beforeEach(() => {
  vi.stubGlobal("fetch", vi.fn((url: string) => {
    if (url.includes("/config")) {
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve({
          data: {
            indexPaths: ["~/.claude/projects"],
            embedding: { provider: "local" },
            server: { port: 3100, host: "localhost" },
          },
        }),
      });
    }
    if (url.includes("/index/status")) {
      return Promise.resolve({
        ok: true,
        json: () => Promise.resolve({ data: { status: "idle", lastIndexed: null, conversationCount: 0 } }),
      });
    }
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ data: [], meta: { total: 0, limit: 20 } }),
    });
  }));
});

describe("App routing", () => {
  test("renders Dashboard at root route '/'", () => {
    render(
      <MemoryRouter initialEntries={["/"]}>
        <App />
      </MemoryRouter>,
    );
    expect(screen.getByText("Recent Conversations")).toBeInTheDocument();
  });

  test("renders Search at '/search' route", () => {
    render(
      <MemoryRouter initialEntries={["/search"]}>
        <App />
      </MemoryRouter>,
    );
    expect(screen.getByRole("heading", { name: "Search" })).toBeInTheDocument();
  });

  test("renders Browse at '/browse' route", () => {
    render(
      <MemoryRouter initialEntries={["/browse"]}>
        <App />
      </MemoryRouter>,
    );
    expect(screen.getByRole("heading", { name: "Browse" })).toBeInTheDocument();
  });

  test("renders Settings at '/settings' route", async () => {
    render(
      <MemoryRouter initialEntries={["/settings"]}>
        <App />
      </MemoryRouter>,
    );
    await waitFor(() => {
      expect(screen.getByRole("heading", { name: "Settings" })).toBeInTheDocument();
    });
  });
});
