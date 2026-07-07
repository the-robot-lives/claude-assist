defmodule DesigningDerobot.Auth.Providers.ProviderReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Auth.Providers.Provider
end
