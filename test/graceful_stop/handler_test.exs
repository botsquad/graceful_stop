defmodule GracefulStop.HandlerTest do
  use ExUnit.Case

  alias GracefulStop.Handler

  setup do
    Process.register(self(), GracefulStop.Test)
    :ok
  end

  test "handler installed" do
    assert Process.whereis(:erl_signal_server)
    assert [Handler] = :gen_event.which_handlers(:erl_signal_server)
  end

  test "handler responds to get_status command" do
    assert :running = Handler.get_status()
  end

  test "system_stop calls :init.stop()" do
    Handler.system_stop()
    assert_receive :init_stop
  end

  test "system_stop calls the hooks" do
    Application.put_env(:graceful_stop, :hooks, [
      [__MODULE__, :hook, [:hook1]],
      [__MODULE__, :hook, [:hook2]]
    ])

    Handler.system_stop()
    assert_receive :hook1
    assert_receive :hook2
    assert_receive :init_stop
  end

  test "handler status = :stopping while system is stopping" do
    Application.put_env(:graceful_stop, :hooks, [[__MODULE__, :hook, [:hook1, 50]]])
    Handler.system_stop()
    Process.sleep 10
    assert :stopping = Handler.get_status()
    assert_receive :hook1
    assert_receive :init_stop
  end

  test "system_stop kills hooks that are taking too long" do
    Application.put_env(:graceful_stop, :hook_timeout, 100)

    Application.put_env(:graceful_stop, :hooks, [
      [__MODULE__, :hook, [:slow, 500]],
      [__MODULE__, :hook, [:slower, 600]]
    ])

    Handler.system_stop()
    refute_receive :slow, 1000
    refute_receive :slower, 1000
    assert_receive :init_stop
    Application.put_env(:graceful_stop, :hooks, [])
  end

  test "sigterm initiates system stop" do
    :gen_event.notify(:erl_signal_server, :sigterm)
    assert_receive :init_stop
  end

  def hook(arg, wait \\ 0) do
    Process.sleep(wait)
    send(GracefulStop.Test, arg)
  end
end
