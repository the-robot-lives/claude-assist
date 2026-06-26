defmodule Therobotmakes.Versioned.Strings.StringReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Versioned.Strings.String
end
