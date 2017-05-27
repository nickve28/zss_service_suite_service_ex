defmodule ZssService.Service.TimerTest do
  use ExUnit.Case
  alias ZssService.Service.Timer
  alias ZssService.Mocks.DateTime, as: DateTimeStub

  doctest Timer

  describe "when measuring time" do

    setup do
      DateTimeStub.enable

      on_exit(fn ->
        DateTimeStub.disable
      end)
    end

    test "#stop should measure the difference between start and end" do
      #DateTime.from_iso8601 would have been preferable, but we need to ensure 1.3 support
      {:ok, time} = 1_506_642_600_000_000_000 #"2017-09-28T23:50:00.000Z"
      |> DateTime.from_unix(:nanoseconds)

      DateTimeStub.stub(:utc_now, time)

      start = Timer.start

      #add 1123 miliseconds
      {:ok, end_time} = 1_506_642_601_123_000_000 #"2017-09-28T23:50:01.123Z"
      |> DateTime.from_unix(:nanoseconds)

      DateTimeStub.stub(:utc_now, end_time)

      assert Timer.stop(start) === "1123.000"
    end
  end
end
