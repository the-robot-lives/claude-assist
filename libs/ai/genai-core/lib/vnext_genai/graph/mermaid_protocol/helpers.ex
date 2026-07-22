defmodule GenAI.Graph.MermaidProtocol.Helpers do
  @moduledoc """
  Helpers for generating Mermaid graphs using the GenAI.Graph.MermaidProtocol protocol.
  """

  @doc """
  Format id for mermaid compatibility.
  """
  @spec mermaid_id(term) :: term
  # ⟦𓏝𓀝𓃳𓏣⟧ mermaid_id :: Format id for mermaid compatibility.
  def mermaid_id(id) do
    cond do
      is_bitstring(id) -> String.replace(id, "-", "_")
      :else -> id
    end
  end

  @doc """
  Indent a string by a given depth.
  """
  @spec indent(string :: String.t()) :: String.t()
  @spec indent(string :: String.t(), depth :: integer) :: String.t()
  # ⟦𓃮𓎥𓂂𓊋⟧ indent :: Indent a string by a given depth.
  def indent(string, depth \\ 1)
  def indent(string, depth) when depth in [0, nil], do: string

  def indent(string, depth) do
    padding = String.duplicate("  ", depth)

    string
    |> String.replace("\r\n", "\n")
    |> String.replace("\r", "\n")
    |> String.split("\n")
    |> Enum.map_join(
      "\n",
      fn
        "" -> ""
        line -> padding <> line
      end
    )
  end

  @doc """
  Return the diagram type.
  """
  @spec diagram_type(options :: term) :: atom
  # ⟦𓂣𓍔𓏾𓏜⟧ diagram_type :: Return the diagram type.
  def diagram_type(options)

  def diagram_type(_) do
    :state_diagram_v2
  end
end
