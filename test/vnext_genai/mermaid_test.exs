defmodule GenAI.VNext.MermaidTest do
  use ExUnit.Case,
    async: true

  alias GenAI.VNext.Graph
  alias GenAI.Graph.Link
  alias GenAI.Graph.MermaidProtocol
  alias GenAI.Graph.Node

  describe "Mermaid Render" do
    test "Empty Graph" do
      sut = Graph.new(id: :A)
      {:ok, mermaid} = MermaidProtocol.encode(sut)

      assert """
             stateDiagram-v2
               [*] --> A
               state "Empty Graph" as A
             """ == mermaid
    end

    test "Single Node Graph - no head " do
      sut =
        Graph.new(id: A)
        |> Graph.add_node(Node.new(id: :Node1, name: "N1"))

      {:ok, mermaid} = MermaidProtocol.encode(sut)

      assert """
             stateDiagram-v2
               state "N1" as Node1
             """ == mermaid
    end

    test "Single Node Graph" do
      sut =
        Graph.new(id: :A)
        |> Graph.add_node(Node.new(id: :Node1, name: "N1"), head: true)

      {:ok, mermaid} = MermaidProtocol.encode(sut)

      assert """
             stateDiagram-v2
               [*] --> Node1
               state "N1" as Node1
             """ == mermaid
    end

    test "Graph with Unlinked Node" do
      sut =
        Graph.new(id: :A)
        |> Graph.add_node(Node.new(id: :Node1, name: "N1"), head: true)
        |> Graph.add_node(Node.new(id: :Node2, name: "N2"))

      {:ok, mermaid} = MermaidProtocol.encode(sut)

      assert """
             stateDiagram-v2
               [*] --> Node1
               state "N1" as Node1

               state "N2" as Node2
             """ == mermaid
    end

    test "Graph with Linked Node" do
      sut =
        Graph.new(id: :A)
        |> Graph.add_node(Node.new(id: :Node1, name: "N1"), head: true)
        |> Graph.add_node(Node.new(id: :Node2, name: "N2"))
        |> Graph.add_link(Link.new(:Node1, :Node2))

      {:ok, mermaid} = MermaidProtocol.encode(sut)

      assert """
             stateDiagram-v2
               [*] --> Node1
               state "N1" as Node1
               Node1 --> Node2

               state "N2" as Node2
             """ == mermaid
    end

    test "Graph with MultiLink" do
      sut =
        Graph.new(id: :A)
        |> Graph.add_node(Node.new(id: :Node1, name: "N1"), head: true)
        |> Graph.add_node(Node.new(id: :Node2, name: "N2"))
        |> Graph.add_node(Node.new(id: :Node3, name: "N3"))
        |> Graph.add_link(Link.new(:Node1, :Node2))
        |> Graph.add_link(Link.new(:Node1, :Node3))
        |> Graph.add_link(Link.new(:Node2, :Node3))

      {:ok, mermaid} = MermaidProtocol.encode(sut)

      assert """
             stateDiagram-v2
               [*] --> Node1
               state "N1" as Node1
               Node1 --> Node3
               Node1 --> Node2

               state "N2" as Node2
               Node2 --> Node3

               state "N3" as Node3
             """ == mermaid
    end
  end
end
