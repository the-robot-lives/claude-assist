defmodule GenAI.Session.State.Directive do
  @moduledoc """
  Directive that is applied to build effective state.
  """
  @vsn 1.0

  require GenAI.Records.Directive
  import GenAI.Records.Directive

  defstruct source: nil,
            entries: [],
            fingerprint: nil,
            vsn: @vsn

  def static(entry, value, source) do
    value = concrete_value(value: value)

    %__MODULE__{
      source: source,
      entries: [{entry, value}],
      fingerprint: source
    }
  end

  # ----------------------
  # apply_directive
  # ----------------------
  def apply_directive(directive, session, context, options)

  def apply_directive(directive, session, context, options) do
    updated_state =
      directive.entries
      |> Enum.reduce(
        session.state,
        &apply_directive_entry(&1, &2, context, options)
      )

    {:ok, %{session | state: updated_state}}
  end

  defp apply_directive_entry({entry = message_entry(msg: msg_id), value}, state, context, options) do
    # update the message by id entry
    # and append message to message list
    state
    |> update_in(
      GenAI.Session.State.entry_path(entry),
      &GenAI.Session.StateEntry.update_entry(&1, value, context, options)
    )
    |> update_in([Access.key(:thread)], &[msg_id | &1])
  end

  defp apply_directive_entry({entry, value}, state, context, options) do
    update_in(
      state,
      GenAI.Session.State.entry_path(entry),
      &GenAI.Session.StateEntry.update_entry(&1, value, context, options)
    )
  end

  # ----------------------
  # expired?/1
  # ----------------------
  def expired?(directive)
  def expired?(_), do: false

  # ----------------------
  # fingerprint/1
  # ----------------------
  def fingerprint(directive)

  def fingerprint(directive),
    do: {:ok, directive.fingerprint}
end
