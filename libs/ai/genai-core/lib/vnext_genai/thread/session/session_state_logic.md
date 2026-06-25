Session State Logic
========================

## Overview
This document defines how we process nodes in a graph during runtime, with a focus on state management and optimization.

## Core Processing Flow

### Node Processing
For each run, we walk through the graph and execute `process_node` on the current path. Key considerations:

1. **State Management**
    - Prior runs may have stored state for nodes
    - We check for existing state when processing nodes with state-dependent actions
    - We load per-node state and mutate if necessary (e.g., if expired)
    - Changes in one node may invalidate state in subsequent nodes

2. **State Storage**
    - Each node's state includes a digest/key indicating which toggles impact the cached state
    - We maintain both global state (current date, memory list, API status) and per-node state
    - As we process nodes, we register them to state, storing:
        - The node itself
        - Generated artifacts (rules, settings, messages)

3. **State Validation**
    - When processing a node, we check if we already have a rule entry for it
    - We verify if existing rules are still valid by checking if the node or state has changed
    - Example: A rule that selects temperature from grid search might need updating

## MVP Implementation

For the initial implementation, we'll rebuild state from scratch on every run while preparing for future optimization:

1. `process_node`:
    - Fetch stored state for the node
    - Get global state/references needed for processing
    - Check if invalidation has occurred by comparing thumbprints
    - Replace stored rules and messages if thumbprint changed
    - Otherwise, return previous state

2. **Artifact Generation**
    - Nodes may generate multiple artifacts (rules, messages, tools)
    - Node processing updates state and appends artifacts to the sequence
    - Rules and settings are only applied when needed (e.g., when inference is required)

### Example Scenario
A node that selects the best model for planning:
- May consider factors like problem type (problem-solving, riddle-solving)
- Advanced picker might use inference and chat context
- Flags are only updated if the message thread has changed
- The rule stays the same, but its output changes based on the flags
- Derived rules/constraints are impacted if the flag list changes

## MVP TODOs
- [ ] Implement `process_node`
- [ ] Add reference to stored state with invalidation checks
- [ ] Apply node to sequence
- [ ] Generate artifacts (messages, rules, etc.)
- [ ] Apply rules on demand to prepare models/settings
- [ ] Defer caching/optimization for future implementation

## Process Flow Diagram
The mermaid flowchart illustrates the complete process from system message through document creation, review, and collaborative refinement.

Key components include:
1. **System Message** - Contains core instructions and NPL conventions
2. **Composite Message** - Handles document generation through the Author Agent
3. **Review Document** - Involves Author, Grader, and Editor agents
4. **Team Collaboration** - Includes multiple reviewers, fact checking, and code testing

The workflow follows a cyclical pattern of creation, review, and refinement until the document meets quality standards.