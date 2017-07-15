defmodule ZssService.Error do
  @moduledoc """
  Provides convenience functions for coercing errors
  """

  @errors ZssService.ErrorCodes.errors
  @internal "500"

  @messages [:developer_message, :user_message, :validation_errors]

  @doc """
  Creates an error model based on the code. Unknown codes get coerced to 500.
  Specify a developer_message, user_message or validation_errors to override the defaults
  Used to enforce a consistent error model.

  ## Examples

  iex> error = ZssService.Error.get_error(400)
  iex> error["developer_message"]
  "The request cannot be fulfilled due to bad syntax."
  iex> error["code"]
  400
  iex> error["user_message"]
  "An error occured"
  iex> error["validation_errors"]
  []

  iex> %{"developer_message" => msg} = ZssService.Error.get_error(400, %{developer_message: "Invalid id sent"})
  iex> msg
  "Invalid id sent"

  """
  def get_error(code, messages \\ %{}) when is_integer(code) do
    with %{"code" => _} = error <- Map.get(@errors, code |> Integer.to_string) do
      #convert to string key
      overrides = messages
      |> Map.take(@messages)
      |> Enum.map(fn {key, value} ->
        {Atom.to_string(key), value}
      end)
      |> Enum.into(%{})

      error
      |> Map.merge(overrides)
    else
      _ -> @errors[@internal]
    end
  end

  @doc """
  Checks whether a status code can be considered an error

  ## Examples

  iex> ZssService.Error.error?(400)
  true

  iex> ZssService.Error.error?(500)
  true

  iex> ZssService.Error.error?(200)
  false

  iex> ZssService.Error.error?(301)
  false
  """
  def error?(code) when code >= 400, do: true
  def error?(_), do: false
end
