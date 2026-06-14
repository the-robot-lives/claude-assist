Postgrex.Types.define(
  Therobotlives.PostgrexTypes,
  [
    Pgvector.Extensions.Vector,
    Geo.PostGIS.Extension
  ] ++ Ecto.Adapters.Postgres.extensions(),
  json: Jason
)
