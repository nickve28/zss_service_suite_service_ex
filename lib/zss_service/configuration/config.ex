defmodule ZssService.Configuration.Config do
  @moduledoc "A struct holding the configuration properties for an instance"

  alias ZssService.Configuration.{Config, Handler}

  @fn_arity 2

  defstruct [
    heartbeat: 1000,
    broker: "tcp://127.0.0.1:7776",
    sid: nil,
    handlers: %{}
  ]

  def new(sid, opts \\ %{}) do
    config = %Config{
      sid: sid |> String.upcase
    }
    Map.merge(config, opts)
  end

  def add_handler(%Config{handlers: handlers} = config, verb, {mod, fun}) do
    case function_exported?(mod, fun, @fn_arity) do
      true ->
        handler_fn = fn payload, message ->
          apply(mod, fun, [payload, message])
        end

        upcase_verb = verb |> String.upcase

        %Config{config | handlers: Map.put(handlers, upcase_verb, handler_fn)}
      false ->
        message = "The function #{mod} => #{fun} with arity #{@fn_arity} was not found"
        {:error, message}
    end
  end
end
