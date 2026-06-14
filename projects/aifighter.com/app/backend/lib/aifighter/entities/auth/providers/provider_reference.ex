defmodule Aifighter.Auth.Providers.ProviderReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Auth.Providers.Provider
end
