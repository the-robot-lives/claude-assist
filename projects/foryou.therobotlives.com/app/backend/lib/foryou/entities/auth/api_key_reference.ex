defmodule Foryou.Auth.ApiKeyReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Foryou.Auth.ApiKey
end
