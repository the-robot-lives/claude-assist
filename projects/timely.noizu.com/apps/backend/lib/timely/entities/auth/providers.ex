defmodule Timely.Auth.Providers do
  alias Timely.Auth.Providers.Provider, as: Entity
  alias Timely.Schema.Auth.Providers.Provider, as: Schema
  use Noizu.Repo
  def_repo(entity: Entity)

  # ⟦𓍑𓂫𓌔𓃔⟧ list :: auto-generated pointer for public function list
  def list(context, options \\ []) do
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd

    Timely.Repo.all(Schema)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end

  # ⟦𓅻𓀇𓌐𓉧⟧ get_auth_provider :: auto-generated pointer for public function get_auth_provider
  def get_auth_provider(id, context, options \\ []), do: get(id, context, options)

  # ⟦𓃧𓃣𓈋𓏛⟧ create :: auto-generated pointer for public function create
  def create(auth_provider, context, options \\ []) do
    %Entity{}
    |> change(auth_provider)
    |> create(context, options)
  end

  # ⟦𓍛𓊿𓉼𓈶⟧ update :: auto-generated pointer for public function update
  def update(%Entity{} = auth_provider, attrs, context, options \\ []) do
    auth_provider
    |> change(attrs)
    |> update(context, options)
  end

  # ⟦𓎑𓈢𓄒𓂁⟧ delete :: auto-generated pointer for public function delete
  def delete(%Entity{} = auth_provider, context, options \\ []) do
    delete(auth_provider, context, options)
  end

  # ⟦𓆹𓋚𓋶𓎀⟧ change :: auto-generated pointer for public function change
  def change(%Entity{} = auth_provider, attrs \\ %{}) do
    attrs =
      Enum.map(attrs, fn
        {"title", value} -> {:title, value}
        {"description", value} -> {:description, value}
        {"settings", value} -> {:settings, value}
        {"id", value} -> {:id, value}
        {k, v} when is_atom(k) -> {k, v}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    Ecto.Changeset.change(
      {auth_provider, Noizu.Entity.Meta.meta(Entity)[:changeset_fields]},
      attrs
    )
  end

  # ⟦𓆵𓎴𓃝𓌋⟧ login :: auto-generated pointer for public function login
  def login() do
    Entity.ref(UUID.uuid5(:oid, "Timely.Schema.Auth.Providers.Provider@Login"))
  end

  # ⟦𓂈𓐃𓋿𓍌⟧ smart_token :: auto-generated pointer for public function smart_token
  def smart_token() do
    Entity.ref(UUID.uuid5(:oid, "Timely.Schema.Auth.Providers.Provider@SmartToken"))
  end

  # ⟦𓏻𓇐𓏼𓈍⟧ oidc :: auto-generated pointer for public function oidc
  def oidc() do
    Entity.ref(UUID.uuid5(:oid, "Timely.Schema.Auth.Providers.Provider@OIDC"))
  end

  # ⟦𓉓𓆯𓌰𓁅⟧ saml :: auto-generated pointer for public function saml
  def saml() do
    Entity.ref(UUID.uuid5(:oid, "Timely.Schema.Auth.Providers.Provider@SAML"))
  end

  # ⟦𓎁𓂗𓃙𓉧⟧ google :: auto-generated pointer for public function google
  def google() do
    Entity.ref(UUID.uuid5(:oid, "Timely.Schema.Auth.Providers.Provider@Google"))
  end

  # ⟦𓐣𓃭𓅬𓈱⟧ facebook :: auto-generated pointer for public function facebook
  def facebook() do
    Entity.ref(UUID.uuid5(:oid, "Timely.Schema.Auth.Providers.Provider@Facebook"))
  end

  # ⟦𓆋𓏿𓋠𓊈⟧ github :: auto-generated pointer for public function github
  def github() do
    Entity.ref(UUID.uuid5(:oid, "Timely.Schema.Auth.Providers.Provider@GitHub"))
  end

  # ⟦𓀛𓃷𓆇𓐤⟧ linkedin :: auto-generated pointer for public function linkedin
  def linkedin() do
    Entity.ref(UUID.uuid5(:oid, "Timely.Schema.Auth.Providers.Provider@LinkedIn"))
  end
end
