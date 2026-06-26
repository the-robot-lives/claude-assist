defmodule Codefresh.Users.Credentials.UserCredentialReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Codefresh.Users.Credentials.UserCredential
end
