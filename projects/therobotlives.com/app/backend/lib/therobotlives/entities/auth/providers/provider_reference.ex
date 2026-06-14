defmodule Therobotlives.Auth.Providers.ProviderReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotlives.Auth.Providers.Provider
end
