defmodule GenAI.Graph.RootTest do
  # import VNextGenAI.Test.Support.Common
  use ExUnit.Case,
    async: true

  alias GenAI.VNext.Graph
  alias GenAI.Graph.Node
  alias GenAI.Graph.Link
  alias GenAI.Records.Link, as: L

  import GenAI.Records.Link

  require Logger
  require GenAI.Records.Link

  def sut(scenario \\ :default)

  def sut(:default) do
    graph_b =
      Graph.new(id: :B)
      |> Graph.add_node(
        Node.new(id: :Node1B, handle: L.graph_handle(scope: :local, name: :foo), name: "N1B"),
        head: true
      )
      |> Graph.add_node(Node.new(id: :Node2B, name: "N2B"))
      |> Graph.add_link(Link.new(:Node1B, :Node2B))

    graph =
      Graph.new(id: :A)
      |> Graph.add_node(Node.new(id: :Node1A, handle: L.graph_handle(name: :foo), name: "N1A"),
        head: true
      )
      |> Graph.add_node(
        Node.new(id: :Node2A, handle: L.graph_handle(scope: :global, name: :bar), name: "N2A")
      )
      |> Graph.add_node(graph_b)
      |> Graph.add_link(Link.new(:Node1A, :Node2A))
      |> Graph.add_link(Link.new(:Node2A, :B))

    hl = GenAI.Graph.NodeProtocol.build_handle_lookup(graph, [])
    el = GenAI.Graph.NodeProtocol.build_node_lookup(graph, [])

    # TODO method to get handles and ids for lookup table from graphs
    # TODO add get node method to Graph.NodeProtocol return {:error, :not_found} by default

    %GenAI.Graph.Root{
      graph: graph
    }
    |> GenAI.Graph.Root.merge_lookup_table_entries(el)
    |> GenAI.Graph.Root.merge_handles(hl)
  end

  def sut(:complex) do
    graph_d =
      Graph.new(id: :D)
      |> Graph.add_node(
        Node.new(id: :Node1D, handle: L.graph_handle(scope: :local, name: :foo), name: "N1D"),
        head: true
      )
      |> Graph.add_node(
        Node.new(id: :Node2D, handle: L.graph_handle(scope: :local, name: :ne), name: "N2D")
      )
      |> Graph.add_link(Link.new(:Node1D, :Node2D))

    graph_c =
      Graph.new(id: :C)
      |> Graph.add_node(
        Node.new(id: :Node1C, handle: L.graph_handle(scope: :local, name: :foo), name: "N1C"),
        head: true
      )
      |> Graph.add_node(
        Node.new(id: :Node2C, handle: L.graph_handle(scope: :local, name: :ne), name: "N2C")
      )
      |> Graph.add_node(graph_d)
      |> Graph.add_link(Link.new(:Node1C, :Node2C))
      |> Graph.add_link(Link.new(:Node2C, :D))

    graph_b =
      Graph.new(id: :B)
      |> Graph.add_node(
        Node.new(id: :Node1B, handle: L.graph_handle(scope: :local, name: :foo), name: "N1B"),
        head: true
      )
      |> Graph.add_node(Node.new(id: :Node2B, name: "N2B"))
      |> Graph.add_node(graph_c)
      |> Graph.add_link(Link.new(:Node1B, :Node2B))
      |> Graph.add_link(Link.new(:Node2B, :C))

    graph =
      Graph.new(id: :A)
      |> Graph.add_node(Node.new(id: :Node1A, handle: L.graph_handle(name: :foo), name: "N1A"),
        head: true
      )
      |> Graph.add_node(
        Node.new(id: :Node2A, handle: L.graph_handle(scope: :global, name: :bar), name: "N2A")
      )
      |> Graph.add_node(graph_b)
      |> Graph.add_link(Link.new(:Node1A, :Node2A))
      |> Graph.add_link(Link.new(:Node2A, :B))

    hl = GenAI.Graph.NodeProtocol.build_handle_lookup(graph, [])
    el = GenAI.Graph.NodeProtocol.build_node_lookup(graph, [])

    # TODO method to get handles and ids for lookup table from graphs
    # TODO add get node method to Graph.NodeProtocol return {:error, :not_found} by default

    %GenAI.Graph.Root{
      graph: graph
    }
    |> GenAI.Graph.Root.merge_lookup_table_entries(el)
    |> GenAI.Graph.Root.merge_handles(hl)
  end

  describe "Basic Graph Root Coverage" do
    test "get entry by element" do
      sut = sut()
      {:ok, element_lookup(element: id)} = GenAI.Graph.Root.element_entry(sut, :Node1B)
      assert id == :Node1B
    end

    test "get node by element" do
      sut = sut()
      {:ok, e} = GenAI.Graph.Root.element(sut, :Node1B)
      assert e.id == :Node1B
    end

    test "get entry by handle" do
      sut = sut()
      {:ok, element_lookup(element: id)} = GenAI.Graph.Root.handle_entry(sut, :foo, :B)
      assert id == :Node1B
    end

    test "get entry by handle element_lookup base" do
      sut = sut()
      {:ok, base} = GenAI.Graph.Root.element_entry(sut, :B)
      {:ok, element_lookup(element: id)} = GenAI.Graph.Root.handle_entry(sut, :foo, base)
      assert id == :Node1B
    end

    test "get entry by handle null base" do
      sut = sut()
      {:ok, element_lookup(element: id)} = GenAI.Graph.Root.handle_entry(sut, :foo, nil)
      assert id == :Node1A
    end

    test "get node by handle" do
      sut = sut()
      {:ok, e} = GenAI.Graph.Root.element_by_handle(sut, :foo, :B)
      assert e.id == :Node1B
    end

    test "get nearest handle entry" do
      sut = sut(:complex)
      {:ok, base} = GenAI.Graph.Root.element_entry(sut, :B)
      {:ok, element_lookup(element: id)} = GenAI.Graph.Root.nearest_handle_entry(sut, :ne, base)
      assert id == :Node2C
    end
  end
end
