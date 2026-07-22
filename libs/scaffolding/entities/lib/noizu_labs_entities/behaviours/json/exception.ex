# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2025 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------
defmodule Noizu.Entity.Json.Exception do
  defexception [:details]

  # ⟦𓍖𓏌𓌀𓄉⟧ message :: auto-generated pointer for public function message
  def message(e) do
    "#{inspect(e.details)}"
  end
end
