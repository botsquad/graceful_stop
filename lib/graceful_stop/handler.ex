defmodule GracefulStop.Handler do
  require Logger

  @name :erl_signal_server

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_) do
    :ok =
      :gen_event.swap_sup_handler(
        @name,
        {:erl_signal_handler, []},
        {__MODULE__, []}
      )

    :ignore
  end

  def get_status() do
    :gen_event.call(@name, __MODULE__, :get_status)
  end

  def system_stop() do
    :gen_event.notify(@name, :sigterm)
  end

  ## gen_event

  defmodule State do
    defstruct timeout: nil,
              hooks: nil,
              status: :running
  end

  def init({_, :ok}) do
    {:ok, %State{}}
  end

  def handle_call(:get_status, state) do
    {:ok, state.status, state}
  end

  def handle_event(:sigterm, state) do
    spawn_link(fn -> perform_stop(state) end)
    {:ok, %State{state | status: :stopping}}
  end

  def handle_info(:resume, state) do
    {:ok, %State{state | status: :running}}
  end
  def handle_info(message, state) do
    # Logger.info "handle_info: #{inspect message}"
    {:ok, state}
  end

  defp perform_stop(state) do
    Logger.debug("Initiating graceful stop…")

    hooks = Application.fetch_env!(:graceful_stop, :hooks)
    timeout = Application.fetch_env!(:graceful_stop, :hook_timeout)

    hooks
    |> log_hooks()
    |> Enum.map(&Kernel.apply(Task, :async, &1))
    |> Task.yield_many(timeout)
    |> Enum.zip(hooks)
    |> kill_slow_hooks()

    Logger.debug("Calling :init.stop()")
    init_stop()
  end

  defp log_hooks([]), do: []

  defp log_hooks(hooks) do
    Logger.debug("Calling #{Enum.count(hooks)} shutdown hooks")
    hooks
  end

  defp kill_slow_hooks(tasks_with_results) do
    Enum.map(tasks_with_results, fn {{task, res}, hook} ->
      if res == nil do
        Logger.warn("Killing slow shutdown task #{inspect(hook)}")
        Task.shutdown(task, :brutal_kill)
      end
    end)
  end

  if Mix.env() == :test do
    def init_stop() do
      send(GracefulStop.Test, :init_stop)
      send(@name, :resume)
    end
  else
    def init_stop() do
      :init.stop()
    end
  end
end
