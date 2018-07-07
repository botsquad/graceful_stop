defmodule GracefulStop.Application do
  use Application

  alias GracefulStop.Handler

  def start(_type, _args) do
    import Supervisor.Spec

    children = [Handler]
    require Logger

    Logger.info("1")

    opts = [strategy: :one_for_one, name: BotsiWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
