# ===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
# ===============================================================================
defmodule GenAI.Graph.NodeBehaviour do
  @moduledoc """
  Behaviour Graph Node Elements must adhere to.
  """
  alias GenAI.Types.Graph, as: G
  alias GenAI.Types, as: T

  # ==================================
  # Behaviour
  # ==================================
  @callback new() :: struct
  @callback new(options :: term) :: struct
  @callback id(graph_node :: term) :: {:ok, G.node_id()} | {:error, any}
  @callback handle(graph_node :: term) :: {:ok, G.node_handle()} | {:error, any}
  @callback handle(graph_node :: term, default :: any) :: {:ok, G.node_handle()} | {:error, any}
  @callback name(graph_node :: term) :: {:ok, String.t()} | {:error, any}
  @callback name(graph_node :: term, default :: any) :: {:ok, String.t()} | {:error, any}
  @callback description(graph_node :: term) :: {:ok, String.t()} | {:error, any}
  @callback description(graph_node :: term, default :: any) :: {:ok, String.t()} | {:error, any}

  # ==================================
  # Support Macros
  # ==================================
  @doc """
  Define the type of a node with default fields included.

  ## Example

  ```elixir
  defnodetype [
     internal: boolean,
  ]
  ```

  """
  defmacro defnodetype(types) do
    types = Macro.expand_once(types, __CALLER__)

    members =
      quote do
        [
          {:id, T.node_id()},
          {:handle, T.node_handle()},
          {:name, T.name()},
          {:description, T.description()},
          unquote_splicing(types),
          {:inbound_links, T.link_map()},
          {:outbound_links, T.link_map()},
          {:finger_print, T.finger_print()},
          {:meta, nil | map() | keyword()},
          {:vsn, float}
        ]
      end

    quote do
      @type t :: %__MODULE__{
              unquote_splicing(members)
            }
    end
  end

  @doc """
  Define the struct of a node with default fields included.

  ## Example
  ```elixir
    defnodestruct [
        value: nil,
    ]
  ```
  """
  defmacro defnodestruct(values) do
    quote do
      @vsn Module.get_attribute(__MODULE__, :vsn, 1.0)
      Kernel.defstruct(
        [
          id: nil,
          handle: nil,
          name: nil,
          description: nil
        ] ++
          (unquote(values) || []) ++
          [
            # edge ids grouped by outlet
            outbound_links: %{},
            # edge ids grouped by outlet
            inbound_links: %{},
            finger_print: nil,
            meta: nil,
            vsn: @vsn
          ]
      )
    end

    # end of quote
  end

  # ==================================
  # Using Macro
  # ==================================
  defmacro __using__(opts \\ nil) do
    quote do
      @provider unquote(opts[:provider]) || GenAI.Graph.NodeProtocol.DefaultProvider
      require GenAI.Graph.NodeBehaviour
      import GenAI.Graph.NodeBehaviour, only: [defnodestruct: 1, defnodetype: 1]
      # import GenAI.Graph.NodeProtocol.DefaultProvider
      @behaviour GenAI.Graph.NodeBehaviour

      defdelegate inspect_custom_details(subject, opts), to: @provider
      defdelegate inspect_low_detail(subject, opts), to: @provider
      defdelegate inspect_medium_detail(subject, opts), to: @provider
      defdelegate inspect_high_detail(subject, opts), to: @provider
      defdelegate inspect_full_detail(subject, opts), to: @provider

      @defimpl GenAI.Graph.NodeBehaviour
      def new(options \\ nil) do
        @provider.new(__MODULE__, options)
      end

      @defimpl GenAI.Graph.NodeBehaviour
      defdelegate id(graph), to: @provider

      @defimpl GenAI.Graph.NodeBehaviour
      defdelegate handle(graph), to: @provider

      @defimpl GenAI.Graph.NodeBehaviour
      defdelegate handle(graph, default), to: @provider

      @defimpl GenAI.Graph.NodeBehaviour
      defdelegate name(graph), to: @provider

      @defimpl GenAI.Graph.NodeBehaviour
      defdelegate name(graph, default), to: @provider

      @defimpl GenAI.Graph.NodeBehaviour
      defdelegate description(graph), to: @provider

      @defimpl GenAI.Graph.NodeBehaviour
      defdelegate description(graph, default), to: @provider

      defoverridable inspect_custom_details: 2,
                     inspect_low_detail: 2,
                     inspect_medium_detail: 2,
                     inspect_high_detail: 2,
                     inspect_full_detail: 2
    end
  end
end
