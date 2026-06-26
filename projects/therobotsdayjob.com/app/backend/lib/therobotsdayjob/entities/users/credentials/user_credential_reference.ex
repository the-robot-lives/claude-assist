defmodule Therobotsdayjob.Users.Credentials.UserCredentialReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: Therobotsdayjob.Users.Credentials.UserCredential
end
