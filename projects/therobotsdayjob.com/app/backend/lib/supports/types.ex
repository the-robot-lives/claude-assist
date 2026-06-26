Postgrex.Types.define(
  Therobotsdayjob.PostgrexTypes,
  [
    Pgvector.Extensions.Vector,
    Geo.PostGIS.Extension
  ] ++ Ecto.Adapters.Postgres.extensions(),
  json: Jason
)
