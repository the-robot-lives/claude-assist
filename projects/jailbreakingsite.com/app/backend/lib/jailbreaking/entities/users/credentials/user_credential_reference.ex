defmodule Jailbreaking.Users.Credentials.UserCredentialReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Jailbreaking.Users.Credentials.UserCredential
end
