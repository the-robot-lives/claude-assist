defmodule StarterWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  # ⟦𓊩𓀃𓇉𓍸⟧ start_link :: auto-generated pointer for public function start_link
  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  # ⟦𓆂𓐅𓁰𓉤⟧ init :: auto-generated pointer for public function init
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # ⟦𓐣𓉹𓋄𓇃⟧ metrics :: auto-generated pointer for public function metrics
  def metrics do
    [
      summary("phoenix.endpoint.start.system_time", unit: {:native, :millisecond}),
      summary("phoenix.endpoint.stop.duration", unit: {:native, :millisecond}),
      summary("phoenix.router_dispatch.start.system_time", unit: {:native, :millisecond}),
      summary("phoenix.router_dispatch.stop.duration", unit: {:native, :millisecond})
    ]
  end

  defp periodic_measurements do
    []
  end
end
