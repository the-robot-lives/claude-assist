import { describe, test, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { Layout } from "../../components/Layout.tsx";

describe("Layout", () => {
  test("renders navbar with 'claude-assist' branding", () => {
    render(
      <MemoryRouter>
        <Layout />
      </MemoryRouter>,
    );
    expect(screen.getByText("claude-assist")).toBeInTheDocument();
  });

  test("renders sidebar navigation items", () => {
    render(
      <MemoryRouter>
        <Layout />
      </MemoryRouter>,
    );
    expect(screen.getByText("Explore")).toBeInTheDocument();
    expect(screen.getByText("Datasets")).toBeInTheDocument();
    expect(screen.getByText("Prompts")).toBeInTheDocument();
    expect(screen.getByText("Projects")).toBeInTheDocument();
  });

  test("renders Settings link separated from main nav", () => {
    render(
      <MemoryRouter>
        <Layout />
      </MemoryRouter>,
    );
    expect(screen.getByText("Settings")).toBeInTheDocument();
  });

  test("shows 'Indexed' status indicator", () => {
    render(
      <MemoryRouter>
        <Layout />
      </MemoryRouter>,
    );
    expect(screen.getByText("Indexed")).toBeInTheDocument();
  });
});
