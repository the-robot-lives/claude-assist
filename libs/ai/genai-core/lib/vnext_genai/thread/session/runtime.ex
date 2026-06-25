# ===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
# ===============================================================================
defmodule GenAI.Session.Runtime do
  @moduledoc """
  Tracks runtime/operating time state of session/thread.
  """

  @vsn 1.0
  defstruct command: :default,
            config: [],
            data: %{},
            monitors: %{},
            meta: %{},
            vsn: @vsn

  @doc """
  Setup new Runtime struct.
  """
  def new(options \\ nil)

  def new(options) do
    %__MODULE__{
      command: options[:command] || :default
    }
  end

  @doc """
  Apply specified command to runtime struct.
  """
  def command(runtime, command_config, context, options \\ nil)

  def command(%__MODULE__{} = runtime, command_config, context, options) do
    {command, config} = prepare_command(command_config, context, options)
    # deal with merging config
    x = %__MODULE__{
      runtime
      | command: command,
        config: config,
        monitors: runtime.monitors || %{},
        data: runtime.data || %{},
        meta: runtime.meta || %{}
    }

    {:ok, x}
  end

  # Prepare runtime action command plus config tuple.
  defp prepare_command(command, context, options)
  defp prepare_command(command, _, _) when is_atom(command), do: {command, []}
  defp prepare_command({command, config}, _, _) when is_atom(command), do: {command, config}
end
