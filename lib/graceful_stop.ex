defmodule GracefulStop do
  @moduledoc """
  Documentation for GracefulStop.
  """

  def stop do
    GracefulStop.Handler.system_stop()
  end

  @spec get_status() :: :running | :stopping
  def get_status do
    GracefulStop.Handler.get_status()
  end

end
