defmodule Therobotmakes.Users.Credentials.UserCredentialReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotmakes.Users.Credentials.UserCredential
end
