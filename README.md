# GracefulStop

Gracefully calls `:init.stop()` after running user-configured shutdown
hooks.

Also catches `SIGTERM` signal to gracefully stop the system and run
the shutdown hooks.

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
