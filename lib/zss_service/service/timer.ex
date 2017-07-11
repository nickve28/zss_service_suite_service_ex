defmodule ZssService.Service.Timer do
  @moduledoc """
  A module that contains a struct to keep track of the time passed between certain operations.
  """

  @datetime Application.get_env(:zss_service, :datetime_module) || DateTime
  @to_millis 1_000_000
  @doc """
  Starts the timer, and returns the start time

  ## Example

  iex> time = ZssService.Service.Timer.start()
  iex> is_integer(time)
  true
  """
  def start do
    @datetime.utc_now()
    |> DateTime.to_unix(:nanoseconds)
  end

  @doc """
  Gets the difference between the given start time and the current time.
  Gives back the result in seconds with 3 digit precision
  Intended to measure an operations' end time

  ## Example

  iex> time = ZssService.Service.Timer.start()
  iex> result = ZssService.Service.Timer.stop(time)
  iex> is_binary(result)
  true
  """
  def stop(time) do
    current_time = @datetime.utc_now()
    |> DateTime.to_unix(:nanoseconds)

    diff = current_time - time
    diff = diff / @to_millis

    :erlang.float_to_binary(diff, decimals: 3)
  end
end
