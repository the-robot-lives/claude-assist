defmodule Aifighter.Users.Credentials.UserCredentialReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Aifighter.Users.Credentials.UserCredential
end
