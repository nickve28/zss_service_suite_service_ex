defmodule ZssService.Service.MessageHandler do
  @moduledoc """
  A module that contains the logic to handle all message frames that the workers receive
  """

  alias ZssService.Message
  import ZssService.Error
  import ZssService.Service.Util, only: [send_reply: 2]
  require Logger

  @service_supervisor Application.get_env(:zss_service, :service_supervisor)

  @success "200"
  @not_found "404"
  @internal "500"

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
          status: @not_found,
          type: "REP"
        }
        send_reply(socket, reply)
    end
  end

  @doc "Catch any non matched message and dont crash the process"
  def handle_msg(_, _, _) do
    :ok #match all in case, TODO: log
  end

  @doc """
  Processes the result that the client specified handler returned, and create the appropriate reply message
  """
  defp process_result(msg, handler_fn) do
    with {:ok, {result, result_message}} <- handler_fn.(msg.payload, to_zss_message(msg)),
         status <- get_status(result_message)
    do
      reply_payload = get_reply_payload(result, status)

      is_no_content = result == nil && !error?(status)
      status = case is_no_content do
        true -> 204
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
  Get the status of the message, and default to the specified default (or "200")
  Empty strings get converted to the specified default.
  """
  defp get_status(message, default \\ @success) do
    message
    |> Map.get(:status, default)
    |> case do
      "" -> default
      code -> code
    end
    |> String.to_integer
  end

  @doc """
  Handle error replies from handler functions
  """
  defp handle_error(error, msg) do
    {:error, {_error_payload, error_message}} = error
    status = get_status(error_message, @internal)
    error = get_error(status)

    %Message{msg |
      payload: error,
      status: status |> Integer.to_string,
      type: "REP"
    }
  end
end
