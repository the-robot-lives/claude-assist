defmodule NoizuSite.Auth.Providers.ProviderReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: NoizuSite.Auth.Providers.Provider
end
