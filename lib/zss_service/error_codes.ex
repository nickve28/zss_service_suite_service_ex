defmodule ZssService.ErrorCodes do
  @moduledoc false

  @errors %{
    "400" => %{
      "developer_message" => "The request cannot be fulfilled due to bad syntax.",
      "user_message" => "An error occured",
      "code" => 400,
      "validation_errors" => []
    },
    "401" => %{
      "developer_message" => "User authentication token has expired or is missing",
      "user_message" => "This resource is only available after logging in.",
      "code" => 401,
      "validation_errors" => []
    },
    "403" => %{
      "developer_message" => "User does not have enough privileges to access this resource.",
      "user_message" => "You do not have access to this resource.",
      "code" => 403,
      "validation_errors" => []
    },
    "404" => %{
      "developer_message" => "The resource could not be found.",
      "user_message" => "The content you requested was not found.",
      "code" => 404,
      "validation_errors" => []
    },
    "422" => %{
      "developer_message" => "The server was unable to process the instructions contained in the request.",
      "user_message" => "The request you made can't be handled. Please review your data.",
      "code" => 422,
      "validation_errors" => []
    },
    "429" => %{
      "developer_message" => "You have sent too many requests in a given amount of time.",
      "user_message" => "Please wait a while before trying to access this content again",
      "code" => 429,
      "validation_errors" => []
    },
    "500" => %{
      "developer_message" => "There was an error while processing this request. There is probably something wrong with the API server.",
      "user_message" => "There was an error while processing this request.",
      "code" => 500,
      "validation_errors" => []
    },
    "599" => %{
      "developer_message" => "Connection timeout while processing this request.",
      "user_message" => "Connection timeout while processing this request.",
      "code" => 599,
      "validation_errors" => []
    }
  }

  def errors, do: @errors
end
