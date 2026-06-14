defmodule Iotgo.Users.Credentials.UserCredentialReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Iotgo.Users.Credentials.UserCredential
end
