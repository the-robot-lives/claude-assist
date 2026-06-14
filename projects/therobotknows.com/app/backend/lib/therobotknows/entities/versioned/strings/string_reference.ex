defmodule Therobotknows.Versioned.Strings.StringReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotknows.Versioned.Strings.String
end
