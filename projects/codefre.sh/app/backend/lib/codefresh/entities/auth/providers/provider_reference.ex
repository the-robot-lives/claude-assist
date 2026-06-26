defmodule Codefresh.Auth.Providers.ProviderReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Auth.Providers.Provider
end
