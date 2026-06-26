defmodule Codefresh.Versioned.Strings.StringReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Versioned.Strings.String
end
