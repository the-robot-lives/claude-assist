defmodule GenAI.VNext.GraphTest do
  use ExUnit.Case,
    async: true

  doctest GenAI.VNext.Graph

  describe "Advanced Nested Links" do
    @doc """
    Build a complex graph with nested nodes and build nested node lookup table.
    the lookup table is a separate data structure stored in a new graph root structure
    """
    test "Build nested link lookup table" do
    end

    @doc """
    Scoped Node Handles for easily pointing to key parts of loop graphs etc.
    Handles by default are global but {:local, handle} tuples can be used for over writable handles based on scope
    Local handles can override standard handles. This involves a tweak to how handles are looked up in a node
    {:global, handle} entries are forced unique and can not be overwritten
    introduce a handle struct node_handle(scope, name)
    """
    test "Node Handle Scoping" do
    end

    @doc """
    Clone Operation to generate new unique ids when copying a graph segment.
    """
    test "Graph Clone" do
    end
  end
end
