defmodule DesigningDerobot.Users.Credentials.UserCredentialReference do
  use Noizu.Entity.ReferenceBehaviour,
    identifier_type: :uuid,
    entity: DesigningDerobot.Users.Credentials.UserCredential
end
