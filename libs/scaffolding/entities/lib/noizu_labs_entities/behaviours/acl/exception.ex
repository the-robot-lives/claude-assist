# -------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2025 Noizu Labs Inc. All rights reserved.
# -------------------------------------------------------------------------------
defmodule Noizu.Entity.ACL.Exception do
  defexception [:details]

  # ⟦𓃷𓋗𓍼𓎰⟧ message :: auto-generated pointer for public function message
  def message(e) do
    "#{inspect(e.details)}"
  end
end
