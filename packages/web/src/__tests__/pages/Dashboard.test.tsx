import { describe, test, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Dashboard } from "../../pages/Dashboard.tsx";

beforeEach(() => {
  vi.stubGlobal("fetch", vi.fn(() =>
    Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ data: [], meta: { total: 0, limit: 20 } }),
    }),
  ));
});

function renderWithRouter(ui: React.ReactElement) {
  return render(<MemoryRouter>{ui}</MemoryRouter>);
}

describe("Dashboard", () => {
  test("renders search input with placeholder 'Search conversations...'", () => {
    renderWithRouter(<Dashboard />);
    expect(
      screen.getByPlaceholderText("Search conversations..."),
    ).toBeInTheDocument();
  });

  test("renders four stat cards", () => {
    renderWithRouter(<Dashboard />);
    expect(screen.getByText("Conversations")).toBeInTheDocument();
    expect(screen.getByText("Projects")).toBeInTheDocument();
    expect(screen.getByText("Dataset Entries")).toBeInTheDocument();
    expect(screen.getByText("Last Indexed")).toBeInTheDocument();
  });

  test("renders 'Recent Conversations' heading", () => {
    renderWithRouter(<Dashboard />);
    expect(screen.getByText("Recent Conversations")).toBeInTheDocument();
  });

  test("shows index instruction when no conversations", async () => {
    renderWithRouter(<Dashboard />);
    await waitFor(() => {
      expect(screen.getByText("claude-assist index")).toBeInTheDocument();
    });
  });
});
