defmodule Example.Auth do
  def start do
    config = "CLAIM"
    |> ZssService.get_instance config
    |> ZssService.add_verb("verify", {Examples.SampleHandler, :verify})

    ZssService.Service.run config

    loop
  end

  def loop() do #Keep the script running
    loop()
  end
end

defmodule Examples.SampleHandler do
  defmodule VerifyPayload do
    defstruct [
      permissions: [],
      resourceId: nil,
      resourceType: nil,
      userId: nil
    ]

    def new(payload) do
      %VerifyPayload{
        permissions: payload["permissions"],
        resourceId: payload["resourceId"],
        resourceType: payload["resourceType"],
        userId: payload["userId"]
      }
    end
  end

  @claims %{
    "123" => [
      %{permissions: ["read"], resourceId: "1", resourceType: "user"},
      %{permissions: ["read", "update"], resourceId: "2", resourceType: "user"},
      %{permissions: ["read"], resourceId: "56c1ec9fd4b053ab0d278847", resourceType: "subscription"}
    ],
    "456" => [
      %{permissions: ["read", "update"], resourceId: "2", resourceType: "user"}
    ]
  }

  def verify(payload, message) do
    result = VerifyPayload.new(payload)
    |> verify_access
    |> case do
      {:ok, result} -> {:ok, {result, message}}
      {:error, :unauthorized} -> {:ok, {%{code: 403, userMessage: "Forbidden", developerMessage: "Forbidden"}, Map.put(message, :status, "403")}}
    end
  end

  defp verify_access(%VerifyPayload{} = payload) do
    user_claims = Map.get(@claims, payload.userId)
    claim = Enum.find(user_claims, fn %{resourceId: r_id, resourceType: r_type, permissions: permissions} ->
      id_match = r_id === payload.resourceId
      type_match = r_type === payload.resourceType
      has_permission = Enum.member?(permissions, List.first(payload.permissions))

      id_match && type_match && has_permission
    end)

    case claim do
      nil -> {:error, :unauthorized}
      claim -> {:ok, claim}
    end
  end
end


Example.Pong.start
