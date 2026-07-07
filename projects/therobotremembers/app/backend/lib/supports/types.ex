Postgrex.Types.define(
  TheRobotRemembers.PostgrexTypes,
  [
    Pgvector.Extensions.Vector,
    # Apache AGE `agtype` passthrough (text) — otherwise any agtype result column fails to describe.
    TheRobotRemembers.Postgrex.Agtype
  ] ++ Ecto.Adapters.Postgres.extensions(),
  json: Jason
)
