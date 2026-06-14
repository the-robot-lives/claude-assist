defmodule NoizuSite.Users.Credentials.UserCredentialReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: NoizuSite.Users.Credentials.UserCredential
end
