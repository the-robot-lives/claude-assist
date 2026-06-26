defmodule Therobotsdayjob.Versioned.Strings.StringReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotsdayjob.Versioned.Strings.String
end
