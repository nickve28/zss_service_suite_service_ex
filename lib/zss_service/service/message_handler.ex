defmodule ZssService.Service.MessageHandler do
  @moduledoc """
  A module that contains the logic to handle all message frames that the workers receive
  """

  alias ZssService.Message
  alias ZssService.Service.Timer
  import ZssService.Error
  import ZssService.Service.Util, only: [send_reply: 2]
  require Logger

  @service_supervisor Application.get_env(:zss_service, :service_supervisor) || ZssService.ServiceSupervisor

  @success 200
  @no_content 204
  @not_found 404
  @internal 500

  @doc """
  Handles heartbeat REP
  """
  def handle_msg(%Message{address: %{verb: "HEARTBEAT"}}, _, _) do
    :ok
  end

  @doc """
  Handles UP REP
  """
  def handle_msg(%Message{address: %{verb: "UP"}}, _, _) do
    :ok
  end

  @doc """
  Handles DOWN message from SMI
  """
  def handle_msg(%Message{address: %{verb: "DOWN", sid: "SMI"}}, _, %{supervisor: supervisor}) do
    Logger.info("Shutting down process after DOWN message from SMI..")
    @service_supervisor.stop(supervisor)
  end

  @doc """
  Handles REQ messages intended to run a registered verb.
  """
  def handle_msg(%Message{type: "REQ"} = msg, socket, %{config: %{handlers: handlers}}) do
    Logger.info("Received message #{msg.identity} routed to #{msg.address.verb}")

    handler_fn = Map.get(handlers, msg.address.verb)

    case handler_fn do
      handler_fn when is_function(handler_fn) -> #is a function handler
        reply = process_result(msg, handler_fn)
        send_reply(socket, reply)
      _ -> #no matching handler found. Default to 404
        reply = %Message{msg |
          status: @not_found |> Integer.to_string,
          type: "REP"
        }
        send_reply(socket, reply)
    end
  end

  @doc "Catch any non matched message and dont crash the process"
  def handle_msg(msg, _, _) do
    Logger.warn("Unmatched message: #{inspect msg}")
    :ok #match all in case, TODO: log
  end

  @doc """
  Processes the result that the client specified handler returned, and create the appropriate reply message
  """
  defp process_result(msg, handler_fn) do
    start_time = Timer.start

    worker_reply = case handler_fn.(msg.payload, to_zss_message(msg)) do
      {:ok, result} -> {:ok, result, @success}
      {:ok, result, code} -> {:ok, result, code}
      {:error, result} -> {:error, result, @internal}
      {:error, result, code} -> {:error, result, code}
      _ -> {:error, %{}, @internal}
    end

    message = with {:ok, result, status} <- worker_reply
    do
      reply_payload = get_reply_payload(result, status)

      is_no_content = result == nil && !error?(status)
      status = case is_no_content do
        true -> @no_content
        _ -> status
      end

      %Message{msg |
        payload: reply_payload,
        type: "REP",
        status: status |> Integer.to_string
      }
    else
      err -> handle_error(err, msg)
    end

    response_time = Timer.stop(start_time)
    %{headers: headers} = message
    new_headers = Map.put(headers, "response-time", response_time)
    %Message{message | headers: new_headers}
  end

  defp get_reply_payload(_result, true) do
    get_error(@internal |> String.to_integer)
  end

  defp get_reply_payload(result, _) do
    result
  end

  @doc """
  Convert a message to ZSS specified headers to send to clients
  """
  defp to_zss_message(%Message{headers: headers}), do: %{headers: headers}

  @doc """
  Handle error replies from handler functions
  """
  defp handle_error({:error, result, status}, msg) do
    error = get_error(status, result)

    %Message{msg |
      payload: error,
      status: status |> Integer.to_string,
      type: "REP"
    }
  end

  defp handle_error(_, msg) do
    error = get_error(@internal)

    %Message{msg |
      payload: error,
      status: @internal |> Integer.to_string,
      type: "REP"
    }
  end
end
