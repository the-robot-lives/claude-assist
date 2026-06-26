defmodule Therobotmakes.Auth.Providers.ProviderReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Auth.Providers.Provider
end
