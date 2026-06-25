# ===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
# ===============================================================================

defmodule GenAI.Session.State.SettingEntry do
  @moduledoc """
  Dynamic Option/Setting Entry.

  ## Background
  At runtime, as needed, directives are unpacked into SettingEntries.
  Constraints and Selectors are merged together to get effective value as of that point in time.
  Any other options current entry depends on are recursively processed as well.
  """
  alias GenAI.Records, as: R
  alias GenAI.Session.State

  require GenAI.Records.Session

  defstruct name: nil,
            effective: nil,
            selectors: [],
            constraints: [],
            references: [],
            impacts: [],
            updated_on: nil

  @type t :: %__MODULE__{
          name: term,
          effective: R.Session.effective_value() | nil,
          selectors: list(R.Session.selector()),
          constraints: list(R.Session.constraint()),
          references: list(term),
          impacts: list(term),
          updated_on: DateTime.t() | nil
        }

  # -------------------------
  # effective_expired?/4
  # -------------------------
  @spec expired?(__MODULE__.t(), term, term) :: boolean
  def expired?(this, context, options)

  def expired?(this = %__MODULE__{}, _, _) do
    case this.effective do
      R.Session.effective_value(expired?: false) ->
        # TODO - [ ] TTL Checks
        # Update entry in state mark effective expired to avoid need for recalculation.
        {false, this}

      _ ->
        {true, this}
    end
  end

  # ------------------------
  # reference_expired?/5
  # ------------------------
  @spec reference_expired?(
          __MODULE__.t(),
          R.Session.state(),
          R.Session.context(),
          R.Session.options()
        ) :: {boolean, {__MODULE__.t(), R.Session.state(), Map.t()}}
  @spec reference_expired?(
          __MODULE__.t(),
          R.Session.state(),
          R.Session.context(),
          R.Session.options(),
          Map.t()
        ) :: {boolean, {__MODULE__.t(), R.Session.state(), Map.t()}}
  def reference_expired?(this, session_state, context, options, memo \\ %{})

  def reference_expired?(this = %__MODULE__{}, session_state, context, options, memo) do
    case expired?(this, context, options) do
      {true, this} ->
        {true, {this, session_state, memo}}

      {false, this} ->
        {
          updated_references,
          {expired?, updated_session_state, updated_memo}
        } = do_reference_expired(this.references, session_state, context, options, memo)

        effective =
          case {expired?, this.effective} do
            {false, _} -> this.effective
            {e, x = R.Session.effective_value()} -> R.Session.effective_value(x, expired?: e)
            {_, x} -> x
          end

        update = %__MODULE__{this | references: updated_references, effective: effective}

        # Return
        {expired?, {update, updated_session_state, updated_memo}}
    end
  end

  defp do_reference_expired(references, session_state, context, options, memo) do
    Enum.map_reduce(
      references,
      {false, session_state, memo},
      fn
        reference, {false, acc_session_state, acc_memo} ->
          {expired?, {updated_reference, acc_session_state, acc_memo}} =
            State.reference_expired?(
              reference,
              acc_session_state,
              context,
              options,
              acc_memo
            )

          {updated_reference, {expired?, acc_session_state, acc_memo}}

        reference, acc = {true, _, _} ->
          {reference, acc}
      end
    )
  end

  # -------------------------
  # effective_value/5
  # -------------------------
  @doc """
  Calculate or returned cached effective value for a given setting.

  ## Note

  If selector depends on input of other settings/artifacts (like chat thread) it will in turn insure dependencies are resolved.

  TODO - default value support
  """
  @spec effective_setting(
          __MODULE__.t(),
          R.Session.state(),
          R.Session.context(),
          R.Session.options()
        ) ::
          {{:ok, value :: term} | {:error, term},
           {__MODULE__.t(), R.Session.state(), memo :: map()}}
  @spec effective_setting(
          __MODULE__.t(),
          R.Session.state(),
          R.Session.context(),
          R.Session.options(),
          memo :: map()
        ) ::
          {{:ok, value :: term} | {:error, term},
           {__MODULE__.t(), R.Session.state(), memo :: map()}}
  def effective_setting(this, state, context, options, memo \\ %{})

  def effective_setting(nil, _, _, _, _) do
    {:error, :unset}
  end

  def effective_setting(this, state, context, options, memo) do
    with {false, {this = %{effective: R.Session.effective_value(value: value)}, state, memo}} <-
           reference_expired?(this, state, context, options, memo) do
      {{:ok, value}, {this, state, memo}}
    else
      {_, this, state, memo} ->
        do_effective_setting(this, state, context, options, memo)
    end
  end

  defp do_effective_setting(this, state, context, options, memo)
  defp do_effective_setting(this, state, _, _, memo) do
    {{:ok, :wip}, {this, state, memo}}
  end

  # TODO do_effective_setting implementation
  # TODO load_references
  # TODO mark_reference
  # TODO mark_references
  # TODO apply_selector
  # TODO apply_constraint

  #
  #  def effective_setting(this, default, state, context, options)
  #  def effective_setting(nil, default, state, context, options) do
  #    {:ok, {default, state}}
  #  end
  #  def effective_setting(this, default, state, context, options) do
  #    # @TODO cyclic loop protection.
  #    cond do
  #      is_nil(this.effective) || effective_expired?(this.effective, state, context, options) ->
  #        case do_effective_setting(this, this.selectors, state, context, options) do
  #          {:error, :unresolved} -> {:ok, {default, state}}
  #          {:error, :unset} -> {:ok, {default, state}}
  #          {:ok, {value, state}} -> {:ok, {value, state}}
  #        end
  #      :else ->
  #        case this.effective do
  #          effective_value(value: {:concrete, value}) ->
  #            {:ok, {value, state}}
  #        end
  #    end
  #  end
end
