Postgrex.Types.define(
  TheRobotRemembers.PostgrexTypes,
  [
    Pgvector.Extensions.Vector
  ] ++ Ecto.Adapters.Postgres.extensions(),
  json: Jason
)
