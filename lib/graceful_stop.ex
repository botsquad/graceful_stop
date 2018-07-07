defmodule GracefulStop do
  @moduledoc """
  Documentation for GracefulStop.
  """

  def stop do
    GracefulStop.Handler.system_stop()
  end
end
