defmodule GenAI.Graph.LinkTest do
  # import VNextGenAI.Test.Support.Common
  use ExUnit.Case,
    async: true

  alias GenAI.Records, as: R

  require Logger
  require GenAI.Records.Link

  doctest GenAI.Graph.Link
end
