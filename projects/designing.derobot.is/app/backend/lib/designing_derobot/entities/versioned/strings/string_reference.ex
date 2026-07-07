defmodule DesigningDerobot.Versioned.Strings.StringReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Versioned.Strings.String
end
