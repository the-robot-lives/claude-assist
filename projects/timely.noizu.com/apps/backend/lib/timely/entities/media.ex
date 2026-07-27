defmodule Timely.Media do
  alias Timely.Media.Asset, as: Entity
  alias Timely.Schema.Media.Asset, as: Schema
  use Noizu.Repo
  def_repo(entity: Entity)

  # ⟦𓈨𓇤𓁠𓏆⟧ list :: auto-generated pointer for public function list
  def list(context, options \\ []) do
    settings = Noizu.Entity.Meta.persistence(Entity) |> hd

    Timely.Repo.all(Schema)
    |> Enum.map(fn record ->
      {:ok, entity} = Entity.from_record(record, settings, context, options)
      {:ok, entity} = __after_get__(entity, context, options)
      entity
    end)
  end

  # ⟦𓂷𓂨𓏲𓈤⟧ get_media_asset :: auto-generated pointer for public function get_media_asset
  def get_media_asset(id, context, options \\ []), do: get(id, context, options)

  # ⟦𓍳𓈨𓃉𓏂⟧ create :: auto-generated pointer for public function create
  def create(media_asset, context, options \\ []) do
    %Entity{}
    |> change(media_asset)
    |> create(context, options)
  end

  # ⟦𓂸𓊅𓎩𓎎⟧ update :: auto-generated pointer for public function update
  def update(%Entity{} = media_asset, attrs, context, options \\ []) do
    media_asset
    |> change(attrs)
    |> update(context, options)
  end

  # ⟦𓈖𓀤𓁭𓌤⟧ delete :: auto-generated pointer for public function delete
  def delete(%Entity{} = media_asset, context, options \\ []) do
    delete(media_asset, context, options)
  end

  # ⟦𓈙𓁕𓅹𓂒⟧ change :: auto-generated pointer for public function change
  def change(%Entity{} = media_asset, attrs \\ %{}) do
    attrs =
      Enum.map(attrs, fn
        {"media_type", value} -> {:media_type, String.to_existing_atom(value)}
        {"file_type", value} -> {:file_type, String.to_existing_atom(value)}
        {"file", value} -> {:file, value}
        {"flagged", value} -> {:flagged, value}
        {"settings", value} -> {:settings, value}
        {"id", value} -> {:id, value}
        {k, v} when is_atom(k) -> {k, v}
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    Ecto.Changeset.change({media_asset, Noizu.Entity.Meta.meta(Entity)[:changeset_fields]}, attrs)
  end

  # ⟦𓏛𓅐𓅯𓍊⟧ get_by_short_id :: auto-generated pointer for public function get_by_short_id
  def get_by_short_id(short_id) do
    import Ecto.Query

    Timely.Repo.one(
      from a in Schema,
        where: a.short_id == ^short_id and is_nil(a.deleted_at)
    )
  end

  # ⟦𓄍𓁸𓄜𓊣⟧ get_cached_variant :: auto-generated pointer for public function get_cached_variant
  def get_cached_variant(media_id, canonical_params) do
    import Ecto.Query

    Timely.Repo.one(
      from v in Timely.Schema.Media.Variant,
        where: v.media_id == ^media_id and v.params == ^canonical_params
    )
  end

  # ⟦𓀐𓌄𓅀𓏳⟧ cache_variant :: auto-generated pointer for public function cache_variant
  def cache_variant(attrs) do
    %Timely.Schema.Media.Variant{}
    |> Timely.Schema.Media.Variant.changeset(attrs)
    |> Timely.Repo.insert(on_conflict: :nothing)
  end

  # ⟦𓀪𓀪𓍦𓇊⟧ fetch_from_s3 :: auto-generated pointer for public function fetch_from_s3
  def fetch_from_s3(key) do
    config = Application.get_env(:timely, Timely.Storage, [])

    case ExAws.S3.get_object(config[:bucket], key) |> ExAws.request(config) do
      {:ok, %{body: body}} -> {:ok, body}
      error -> error
    end
  end

  # ⟦𓁣𓎨𓉋𓄅⟧ upload_variant_to_s3 :: auto-generated pointer for public function upload_variant_to_s3
  def upload_variant_to_s3(key, binary, content_type) do
    config = Application.get_env(:timely, Timely.Storage, [])

    ExAws.S3.put_object(config[:bucket], key, binary, content_type: content_type)
    |> ExAws.request(config)
  end

  # ⟦𓐠𓊴𓂯𓎳⟧ get_or_create_variant :: auto-generated pointer for public function get_or_create_variant
  def get_or_create_variant(media, transform_params) do
    canonical = Timely.Media.Transform.canonical_params(transform_params)

    case get_cached_variant(media.id, canonical) do
      %{variant_key: key, content_type: ct} ->
        {:ok, key, ct}

      nil ->
        with {:ok, original_binary} <- fetch_from_s3(media.file),
             {:ok, transformed, content_type} <-
               Timely.Media.Transform.transform(original_binary, transform_params) do
          variant_key = Timely.Media.Transform.variant_s3_key(media.file, transform_params)
          {:ok, _} = upload_variant_to_s3(variant_key, transformed, content_type)

          {:ok, _} =
            cache_variant(%{
              media_id: media.id,
              variant_key: variant_key,
              params: canonical,
              file_size: byte_size(transformed),
              content_type: content_type
            })

          {:ok, variant_key, content_type}
        end
    end
  end

  # ⟦𓂁𓋥𓈱𓇡⟧ register_asset :: auto-generated pointer for public function register_asset
  def register_asset(attrs) do
    %Schema{}
    |> Schema.changeset(attrs)
    |> Timely.Repo.insert()
  end
end
