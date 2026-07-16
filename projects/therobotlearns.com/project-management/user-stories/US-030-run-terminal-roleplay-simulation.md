---
id: US-030
title: "Run a Terminal Role-Play Simulation"
slug: run-terminal-roleplay-simulation
personas: [P-003, P-001]
epic: "Simulations & Projects"
priority: must-have
complexity: high
tags: [simulation, roleplay, incident-response]
---

# US-030: Run a Terminal Role-Play Simulation

## User Story

**As an** SRE who needs to practice high-pressure scenarios
**I want to** run a terminal role-play simulation via /simulate, such as a production incident response
**So that** I can rehearse decision-making under realistic conditions

## Acceptance Criteria

- **Given** a simulation topic (e.g., "production database outage")
  **When** I run /simulate
  **Then** an interactive scenario unfolds turn by turn in the terminal with evolving state based on my responses

- **Given** I make a decision during the simulation
  **When** I submit it
  **Then** the scenario reacts with consequences consistent with that choice before presenting the next beat

- **Given** the simulation schema defines branching outcomes
  **When** I take actions
  **Then** the path taken and key decisions are logged for later review

- **Given** I want to stop mid-simulation
  **When** I exit
  **Then** partial progress is saved so I don't lose context if I resume later

## Notes
