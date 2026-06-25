# ===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
# ===============================================================================
defmodule GenAI.Session.State do
  @moduledoc """
  Represent status/state such as node state, sessions, message thread, etc.
  """

  require GenAI.Records.Directive

  import GenAI.Records.Directive

  # require GenAI.Records.Session
  defstruct directives: [],
            directive_position: 0,
            thread: [],
            thread_messages: %{},
            stack: %{},
            data_generators: %{},
            options: %{},
            settings: %{},
            model_settings: %{},
            provider_settings: %{},
            safety_settings: %{},
            model: nil,
            tools: %{},
            monitors: %{},
            artifacts: %{},
            vsn: 1.0

  @type t :: %__MODULE__{
          directives: list(),
          directive_position: non_neg_integer(),
          thread: list(),
          thread_messages: map(),
          stack: map(),
          data_generators: map(),
          options: map(),
          settings: map(),
          model_settings: map(),
          provider_settings: map(),
          safety_settings: map(),
          model: term(),
          tools: map(),
          monitors: map(),
          artifacts: map(),
          vsn: float()
        }

  # ===========================================================================
  # entry selectors
  # ===========================================================================
  def entry_path(message_entry(msg: entry)),
    do: [Access.key(:thread_messages), entry]

  def entry_path(stack_entry(element: entry)),
    do: [Access.key(:stack), entry]

  def entry_path(data_generator_entry(generator: entry)),
    do: [Access.key(:data_generators), entry]

  def entry_path(option_entry(option: entry)),
    do: [Access.key(:options), entry]

  def entry_path(setting_entry(setting: entry)),
    do: [Access.key(:settings), entry]

  def entry_path(model_setting_entry(model: model, setting: entry)) do
    with {:ok, name} <- GenAI.ModelProtocol.name(model),
         {:ok, provider} <- GenAI.ModelProtocol.provider(model) do
      [Access.key(:model_settings), Access.key({name, provider}, %{}), entry]
    end

    # do: [Access.key(:model_settings), Access.key(model, %{}), entry]
  end

  def entry_path(provider_setting_entry(provider: provider, setting: entry)),
    do: [Access.key(:provider_settings), Access.key(provider, %{}), entry]

  def entry_path(safety_setting_entry(category: entry)),
    do: [Access.key(:safety_settings), entry]

  def entry_path(model_entry()),
    do: [Access.key(:model)]

  def entry_path(tool_entry(tool: entry)),
    do: [Access.key(:tools), entry]

  def entry_path(monitor_entry(monitor: entry)),
    do: [Access.key(:monitors), entry]

  # ===========================================================================
  #
  # ===========================================================================

  #  defp memoize(entry, value, memo)
  #  defp memoize(entry, value, memo) do
  #    Map.put(memo, entry, value)
  #  end

  # -----------------------
  # new/1
  # -----------------------
  def new(options \\ nil)

  def new(_) do
    %__MODULE__{}
  end

  # -----------------------
  # initialize/4
  # -----------------------
  def initialize(state, runtime, context, options \\ nil)

  def initialize(state, _runtime, _context, _options) do
    {:ok, state}
  end

  # -----------------------
  # monitor/4
  # -----------------------
  def monitor(state, runtime, context, options \\ nil)

  def monitor(state, runtime, _, _) do
    {:ok, {state, runtime}}
  end

  #
  #  # ------------------------
  #  # reference_expired?/5
  #  # ------------------------
  #  @spec reference_expired?(
  #          R.Session.entry_reference(),
  #          __MODULE__.t(),
  #          R.Session.context(),
  #          R.Session.options()
  #        ) :: {boolean, {R.Session.entry_reference(), R.Session.state(), Map.t()}}
  #  @spec reference_expired?(
  #          R.Session.entry_reference(),
  #          __MODULE__.t(),
  #          R.Session.context(),
  #          R.Session.options(),
  #          Map.t()
  #        ) :: {boolean, {R.Session.entry_reference(), R.Session.state(), Map.t()}}
  #  def reference_expired?(reference, this, context, options, memo \\ %{})
  #
  #  def reference_expired?(
  #        reference = R.Session.entry_reference(expired?: true),
  #        this,
  #        _,
  #        _,
  #        memo
  #      ) do
  #    {true, {reference, this, memo}}
  #  end
  #
  #  def reference_expired?(
  #        reference = R.Session.entry_reference(entry: entry, finger_print: finger_print),
  #        this,
  #        context,
  #        options,
  #        memo
  #      ) do
  #    reference_key = {entry, finger_print}
  #
  #    if x = memo[reference_key] do
  #      {x, {R.Session.entry_reference(reference, expired?: x), this, memo}}
  #    else
  #      # todo return nil for unchanged values.
  #      with %SettingEntry{} = entry <- get_in(this, apply_setting_path(reference)),
  #           {expired?, {updated_entry, updated_state, updated_memo}} <-
  #             SettingEntry.reference_expired?(entry, this, context, options, memo) do
  #        updated_state = put_in(updated_state, apply_setting_path(entry), updated_entry)
  #        updated_memo = memoize(reference_key, expired?, updated_memo)
  #
  #        updated_reference =
  #          if expired?,
  #            do: R.Session.entry_reference(reference, expired?: expired?),
  #            else: reference
  #
  #        {expired?, {updated_reference, updated_state, updated_memo}}
  #      else
  #        _ ->
  #          updated_memo = memoize(reference_key, true, memo)
  #          {true, {R.Session.entry_reference(reference, expired?: true), this, updated_memo}}
  #      end
  #    end
  #  end
  #
  #
end
