# GracefulStop

Gracefully calls `:init.stop()` after running user-configured shutdown
hooks.

Also catches `SIGTERM` signal to gracefully stop the system and run
the shutdown hooks.

When running in a Kubernetes-managed cluster, nodes in the cluster
come and go as kubernetes decides. It sends the SIGTERM signal, which
by default triggers a `:init.stop()`. However, you might want to give
the system some time to shut down, running cleanup processes, wait for
running requests to finish, et cetera.

## Usage

After adding `:graceful_stop` to your deps, you can configure it to
call hooks when the application will stop:


```
config :graceful_stop, :hooks, [
  [IO, :puts, ["Stopping the system"]]
]
```


Then: `kill $(pidof beam.smp)` sends a `SIGTERM` signal to your
running BEAM process, and you will notice that you see "Stopping the
system" printed on the console, before it shuts down.

Note that these hooks run *before* any of your OTP applications are
being stopped, so you can do all kinds of things there, without
worrying that parts of your system are already shut down (which would
be the case if you try to trap the `{:EXIT, pid, :shutdown}` message).

There is a `:hook_timeout` setting, defaulting to 15 seconds, which is
the maximum time that a hook can run. Hooks run in parallel, using
`Task.async` / `Task.yield_many`.


## Inspiration

This project was inspired by the
[k8s_traffic_plug](https://github.com/Financial-Times/k8s_traffic_plug)
package and the corresponding [blog
post](https://medium.com/@ellispritchard/graceful-shutdown-on-kubernetes-with-signals-erlang-otp-20-a22325e8ae98).
However, it does not include a Plug. Creating a plug is simple, as you
can call `GracefulStop.get_status()` which returns either `:running`
or `:stopping`, and you can create a plug that serves a HTTP 503
request based on this code.

### Phoenix Plug implementation example

Mount this plug inside your [Phoenix Endpoint](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html) before the router plug is mounted. 
**DO NOT** mount this plug inside your router file.

```elixir
defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :myapp

  ....

  plug MyAppWeb.Plug.TrafficDrain
  plug MyAppWeb.Router  
``` 

Reference implementation of `TrafficDrain` plug.

```elixir
defmodule MyAppWeb.Plug.TrafficDrain do
  @moduledoc """
  Plug for handling Kubernetes readinessProbe.

  Plug starts responding with 503 - Service Unavailable from `/__traffic`, when traffic is being drained.
  Otherwise we respond with 200 - OK.
  """

  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{path_info: ["__traffic"]} = conn, _opts) do
    case GracefulStop.get_status() do
      :stopping ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:service_unavailable, "Draining")
        |> halt()

      :running ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(:ok, "Serving")
        |> halt()
    end
  end

  @impl true
  def call(conn, _opts) do
    conn
  end
end

```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `graceful_stop` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:graceful_stop, "~> 0.1.0"}
  ]
end
```
