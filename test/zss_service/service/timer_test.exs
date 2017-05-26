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
      {:ok, time, _} = DateTime.from_iso8601("2017-09-28T23:50:00.000Z")
      DateTimeStub.stub(:utc_now, time)

      start = Timer.start

      #add 1123 miliseconds
      {:ok, end_time, _} = DateTime.from_iso8601("2017-09-28T23:50:01.123Z")
      DateTimeStub.stub(:utc_now, end_time)

      assert Timer.stop(start) === "1123.000"
    end
  end
end
