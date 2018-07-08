defmodule GracefulStop.Handler do
  require Logger

  @name :erl_signal_server
  @table Module.concat(__MODULE__, Table)

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
    [{:status, status}] = :ets.lookup(@table, :status)
    status
  end

  def system_stop() do
    :gen_event.notify(@name, :sigterm)
  end

  ## gen_event

  defmodule State do
    defstruct timeout: nil,
              hooks: nil
  end

  def init({_, :ok}) do
    :ets.new(@table, [:named_table, :public, read_concurrency: true])
    {:ok, %State{} |> set_status(:running)}
  end

  def handle_event(:sigterm, state) do
    spawn_link(&perform_stop/0)
    {:ok, state |> set_status(:stopping)}
  end

  def handle_info(:resume, state) do
    {:ok, state |> set_status(:running)}
  end
  def handle_info(_message, state) do
    # Logger.info "handle_info: #{inspect message}"
    {:ok, state}
  end

  defp perform_stop() do
    Logger.debug("Initiating graceful stop…")

    hooks = Application.get_env(:graceful_stop, :hooks, [])
    timeout = Application.get_env(:graceful_stop, :hook_timeout, 15_000)

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

  defp set_status(state, status) do
    :ets.delete_all_objects(@table)
    :ets.insert(@table, {:status, status})
    state
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
