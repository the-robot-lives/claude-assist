# ===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
# ===============================================================================
defmodule GenAI.Records.Node do
  @moduledoc """
  Records used by for preparing/processing nodes.
  """

  require Record

  @typedoc """
  Indicate node to process next.
  """
  @type process_next :: record(:process_next, element: any, session: any)
  Record.defrecord(:process_next, element: nil, session: nil)

  @typedoc """
  Indicate no further nodes to process.
  """
  @type process_end :: record(:process_end, element: any, session: any)
  Record.defrecord(:process_end, element: nil, session: nil)

  @typedoc """
  Yield processing for.
  """
  @type process_yield :: record(:process_yield, element: any, yield_for: any, session: any)
  Record.defrecord(:process_yield, element: nil, yield_for: nil, session: nil)

  @typedoc """
  Processing error
  """
  @type process_error :: record(:process_error, element: any, error: any, session: any)
  Record.defrecord(:process_error, element: nil, error: nil, session: nil)
end
