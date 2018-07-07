# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# How long hook functions can run before they are :brutal_kill'ed
config :graceful_stop, :hook_timeout, 15_000

# List of MFAs to run on graceful stop, for instance:
# config :graceful_stop, :hooks, [ [IO, :puts, ["Stopping the system"] ] ]
config :graceful_stop, :hooks, []
