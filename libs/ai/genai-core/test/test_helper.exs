ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])

children = [
  {Finch, name: GenAI.Finch}
]

# See https://hexdocs.pm/elixir/Supervisor.html
# for other strategies and supported options
opts = [strategy: :one_for_one, name: GenAI.Supervisor]
Supervisor.start_link(children, opts)

Mimic.copy(Finch)

ExUnit.start()
