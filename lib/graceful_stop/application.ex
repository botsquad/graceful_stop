defmodule GracefulStop.Application do
  use Application

  alias GracefulStop.Handler

  def start(_type, _args) do
    children = [Handler]
    opts = [strategy: :one_for_one, name: GracefulStop.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
