# ===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
# ===============================================================================
defmodule GenAI.Records.Session do
  @moduledoc """
  Records used by for preparing/encoding VNextGenAI.Session
  """

  require Record

  # =============================================================================
  # Session Records
  # =============================================================================

#
#
#  # *******************************************************
#  # Directive Records
#  # *******************************************************
#
#
#  # ********************************
#  # Directive Entry Records
#  # ********************************
#
#  #----------------------------
#  # concrete_entry
#  #----------------
#  @typedoc """
#  Represents a concrete value, an exact specified (or calculated) value to be used.
#  """
#  @type concrete_entry :: record(:concrete_entry, value: any)
#  Record.defrecord(:concrete_entry, value: nil)
#
#  #----------------------------
#  # range_entry
#  #----------------
#  @typedoc """
#  Represents a range of allowed values for an entry.
#  For simplicity the most recent range overwrites any prior range specifiers.
#  """
#  @type range_entry :: record(:range_entry, from: any, to: any)
#  Record.defrecord(:range_entry, from: nil, to: nil)
#
#  #----------------------------
#  # inclusion_entry
#  #----------------
#  @typedoc """
#  Provide a list of allowed values for an entry.
#  """
#  @type inclusion_entry :: record(:inclusion_entry, values: list(any))
#  Record.defrecord(:inclusion_entry, values: [])
#
#  #----------------------------
#  # exclusion_entry
#  #----------------
#  @typedoc """
#  Provide a set/list of allowed values for an entry.
#  """
#  @type selection_entry :: record(:selection_entry, values: list(any))
#  Record.defrecord(:selection_entry, values: [])
#
#
#  #----------------------------
#  # selection_entry
#  #----------------
#  @typedoc """
#  The constraint (either a lambda, module (default function constraint_directive), or module and function)
#  when called with settings returns a method that for value fields accepts a list of possible values
#  and sorts them by matches and excludes incompatible entries.
#  For numeric fields it returns a method that modifies a range selection.
#  """
#  @type constraint_entry :: record(:constraint_entry, constraint: any, settings: any)
#  Record.defrecord(:constraint_entry, constraint: nil, settings: nil)
#
#  # ********************************
#  # Directive Range Entry Selector Records
#  # ********************************
#  @typedoc """
#  A Range constraint specifies rules and selection logic for which
#  values a numeric float or discrete entry can have.
#
#  - equation a list of equations putting constraints on the value X.
#  - select: rule for final concrete value to pick. Highset, Lowest, Nearest, NearestBelow, NearestAbove.
#  """
#  Record.defrecord(:range_constraint, equations: [], select: nil)

  # *******************************************************
  # Other Records
  # *******************************************************


  # ----------------------------
  # stack_entry Record
  # ----------------------------
  @typedoc """
  Reference to a stack entry.
  """
  @type stack_entry :: record(:stack_entry, item: any)
  Record.defrecord(:stack_entry, item: nil)


  # ----------------------------
  # option_entry Record
  # ----------------------------
  @typedoc """
  Reference to an option entry.
  """
  @type option_entry :: record(:option_entry, option: any)
  Record.defrecord(:option_entry, option: nil)


  # ----------------------------
  # setting_entry Record
  # ----------------------------
  @typedoc """
  Reference to a setting entry.
  """
  @type setting_entry :: record(:setting_entry, setting: any)
  Record.defrecord(:setting_entry, setting: nil)


  # ----------------------------
  # tool_entry Record
  # ----------------------------
  @typedoc """
  Reference to a tool entry.
  """
  @type tool_entry :: record(:tool_entry, tool: any)
  Record.defrecord(:tool_entry, tool: nil)

  # ----------------------------
  # model_entry Record
  # ----------------------------
  @typedoc """
  Reference to a model entry.
  """
  @type model_entry :: record(:model_entry, [])
  Record.defrecord(:model_entry, [])


  # ----------------------------
  # model_setting_entry Record
  # ----------------------------
  @typedoc """
  Reference to a model-specific setting entry.
  """
  @type model_setting_entry ::
          record(:model_setting_entry, model: any, setting: any)
  Record.defrecord(:model_setting_entry, model: nil, setting: nil)


  # ----------------------------
  # provider_setting_entry Record
  # ----------------------------

  @typedoc """
  Reference to a provider-specific setting entry.
  """
  @type provider_setting_entry ::
          record(:provider_setting_entry, provider: any, setting: any)
  Record.defrecord(:provider_setting_entry, provider: nil, setting: nil)


  # ----------------------------
  # safety_setting_entry Record
  # ----------------------------

  @typedoc """
  Reference to a safety setting entry.
  """
  @type safety_setting_entry ::
          record(:safety_setting_entry, category: any)
  Record.defrecord(:safety_setting_entry, category: nil)


  # ----------------------------
  # session_entry Type
  # ----------------------------
  @typedoc """
  Session Dynamic Entry Records
  """
  @type session_entry ::
          stack_entry
          | option_entry
          | setting_entry
          | tool_entry
          | model_entry
          | model_setting_entry
          | provider_setting_entry

  # ----------------------------
  # entry_reference Record
  # ----------------------------

  @typedoc """
  Reference to a session entry with finger print and tracking fields for invalidation tracking.
  """
  @type entry_reference ::
          record(:entry_reference,
            entry: session_entry,
            finger_print: any,
            inserted_at: any,
            updated_at: any
          )
  Record.defrecord(:entry_reference,
    entry: nil,
    expired?: false,
    finger_print: nil,
    inserted_at: nil,
    updated_at: nil
  )

  # ----------------------------
  # selector Record
  # ----------------------------
  # Calculate effective/tentative value for option

  @typedoc """
  Settings to calculate effective/tentative value for entry.
  """
  @type selector ::
          record(:selector,
            id: any,
            handle: any,
            for: any,
            value: any,
            directive: any,
            inserted_at: any,
            updated_at: any,
            impacts: list(any),
            references: list(any)
          )
  Record.defrecord(:selector,
    id: nil,
    handle: nil,
    for: nil,
    value: nil,
    directive: nil,
    inserted_at: nil,
    updated_at: nil,
    impacts: [],
    references: []
  )

  # ----------------------------
  # constraint Record
  # ----------------------------
  # Constraint on allowed option values.

  @typedoc """
  Settings to calculate constraints for entry.
  """
  @type constraint ::
          record(:constraint,
            id: any,
            handle: any,
            for: any,
            value: any,
            directive: any,
            inserted_at: any,
            updated_at: any,
            impacts: list(any),
            references: list(any)
          )
  Record.defrecord(:constraint,
    id: nil,
    handle: nil,
    for: nil,
    value: nil,
    directive: nil,
    inserted_at: nil,
    updated_at: nil,
    impacts: [],
    references: []
  )

  # ----------------------------
  # effective_value Record
  # ----------------------------
  # Constraint computed effective option value with cache tag for invalidation.
  # tracking fields.

  @typedoc """
  Effective value for entry as of point in graph.
  """
  @type effective_value ::
          record(:effective_value,
            id: any,
            handle: any,
            value: any,
            finger_print: any,
            inserted_at: any,
            updated_at: any
          )
  Record.defrecord(:effective_value,
    id: nil,
    handle: nil,
    value: nil,
    finger_print: nil,
    expired?: false,
    inserted_at: nil,
    updated_at: nil
  )

  # ----------------------------
  # tentative_value Record
  # ----------------------------
  # Constraint computed tentative option value with cache tag for invalidation.
  # tracking fields.

  @typedoc """
  Tentative value for entry as of point in graph.
  """
  @type tentative_value ::
          record(:tentative_value,
            id: any,
            handle: any,
            value: any,
            finger_print: any,
            inserted_at: any,
            updated_at: any
          )
  Record.defrecord(:tentative_value,
    id: nil,
    handle: nil,
    value: nil,
    finger_print: nil,
    inserted_at: nil,
    updated_at: nil
  )

  # =============================================================================
  # Session ProcessNodeProtocol Records
  # =============================================================================

  # ----------------------------
  # scope Record
  # ----------------------------
  # Standard input arg (duplicates node, useful for comparing new to old value.

  @typedoc """
  Scope/context. Node, Graph, State, Runtime, etc.
  """
  @type scope ::
          record(:scope,
            graph_node: any,
            graph_link: any,
            graph_container: any,
            session_root: any,
            session_state: any,
            session_runtime: any
          )
  Record.defrecord(:scope,
    graph_node: nil,
    graph_link: nil,
    graph_container: nil,
    session_root: nil,
    session_state: nil,
    session_runtime: nil
  )

  # ----------------------------
  # process_next Record
  # ----------------------------
  # Indicates that the node should be processed next.

  @typedoc """
  Indicate node to process next.
  """
  @type process_next :: record(:process_next, link: any, update: scope)
  Record.defrecord(:process_next, link: nil, update: nil)

  # ----------------------------
  # process_end Record
  # ----------------------------
  # Indicates that processing is complete.

  @typedoc """
  Indicate no further nodes to process.
  """
  @type process_end :: record(:process_end, exit_on: any, update: scope)
  Record.defrecord(:process_end, exit_on: nil, update: nil)

  # ----------------------------
  # process_yield Record
  # ----------------------------
  # Yield before resuming for external response (or wait on other node completion/global state).

  @typedoc """
  Indicate a blocking call/condition must be met before proceeding.
  """
  @type process_yield :: record(:process_yield, yield_for: any, update: scope)
  Record.defrecord(:process_yield, yield_for: nil, update: nil)

  # ----------------------------
  # process_error Record
  # ----------------------------
  # Indicates that an error has occurred.

  @typedoc """
  Indicate error occurred while processing node.
  """
  @type process_error :: record(:process_error, error: any, update: scope)
  Record.defrecord(:process_error, error: nil, update: nil)

  #
  #    #------------------
  #    # node protocol definition helpers.
  #    #------------------
  #
  #    # retrieve n records from data_generator for a given data_set.
  #    Record.defrecord(:data_set, [name: nil, records: 1])
  #
  #    # Grab value from global stack
  #    Record.defrecord(:stack, [item: nil, default: nil])
  #    # Grab sub value from global stack
  #    Record.defrecord(:stack_item_value, [item: nil, path: [], default: nil])
  #
  #    # Grab input value
  #    Record.defrecord(:input, [value: nil, default: nil])
  #    # Grab nested item from input value
  #    Record.defrecord(:input_element, [value: nil, path: [], default: nil])
  #
  #    # grab message state entry or nested entry
  #    Record.defrecord(:message, [id: nil, handle: nil])
  #    Record.defrecord(:message_value, [id: nil, path: nil])
  #    Record.defrecord(:message_filter, [filter: nil])
  #    Record.defrecord(:message_filter_value, [filter: nil, path: []])
  #
  #    # grab link state entry or nested entry
  #    Record.defrecord(:link, [id: nil, handle: nil])
  #    Record.defrecord(:link_value, [id: nil, handle: nil, path: []])
  #    Record.defrecord(:link_filter, [filter: nil])
  #    Record.defrecord(:link_filter_value, [filter: nil, path: []])
  #
  #    # Grab Runtime Flag
  #    Record.defrecord(:runtime, [setting: nil])
  #
  #    # grab tool definition
  #    Record.defrecord(:tool, [id: nil, handle: nil, name: nil])
  #    Record.defrecord(:tool_filter, [filter: nil])
  #
  #    # grab directive by id or handle or by impacts lists (or references list)
  #    Record.defrecord(:directive, [id: nil, handle: nil])
  #    Record.defrecord(:directive_by_tag, [in: nil, not_in: nil, only: nil])
  #
  #    Record.defrecord(:directive_by_source, [source: nil])
  #    Record.defrecord(:directive_by_impacts, [impacts: nil])
  #    Record.defrecord(:directive_by_impacts_all, [impacts_all: nil])
  #    Record.defrecord(:directive_by_references, [references_any: nil])
  #    Record.defrecord(:directive_by_references_all, [references_all: nil])
  #
  #    # grab directive by id or handle
  #    Record.defrecord(:setting, [name: nil])
  #    Record.defrecord(:safety_setting, [name: nil])
  #    Record.defrecord(:model_setting, [name: nil])
  #    Record.defrecord(:provider_setting, [provider: nil, name: nil])
  #
  #
  #
  #    # Force invalidation / Ignore - special methods
  #    Record.defrecord(:ttl, [expiry: 300])
  #    # Values will be converted to the lowest specified unit. So setting day 5, hour 4 will invalidate every 5 * 24 + 4 hours.
  #    Record.defrecord(:time_bucket, [years: nil, months: nil, days: nil, hours: nil, seconds: nil])
  #    def dynmaic_node(), do: {:__genai__, :dynamic}
  #    def finger_print(value, as \\ :auto), do: {{:__genai__, :finger_print, as}, value}
  #    def no_finger_print(value), do: {{:__genai__, :no_finger_print}, value}
end
