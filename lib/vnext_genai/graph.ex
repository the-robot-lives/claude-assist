defmodule GenAI.Graph do
  @moduledoc """
  A module representing a graph structure in the GenAI system.
  This module defines the structure and behavior of a graph,
  including its nodes and the ability to append new nodes.
  """

  @vsn 1.0

  defstruct nodes: [],
            vsn: @vsn

  @doc """
  Appends a new node to the graph.
  """
  def append_node(this, node) do
    %{this | nodes: this.nodes ++ [node]}
  end
end
