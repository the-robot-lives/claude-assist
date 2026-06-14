Postgrex.Types.define(
  NoizuSite.PostgrexTypes,
  [
    Pgvector.Extensions.Vector,
    Geo.PostGIS.Extension
  ] ++ Ecto.Adapters.Postgres.extensions(),
  json: Jason
)
