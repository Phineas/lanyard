defmodule Lanyard.Api.Doc.Schemas.V1.UserNotMonitored do
  alias OpenApiSpex.Schema

  @spec schema() :: OpenApiSpex.Schema.t()
  def schema do
    %Schema{
      title: "UserNotMonitored",
      type: :object,
      properties: %{
        success: %Schema{
          type: :boolean,
          enum: [false],
          description: "Always false",
          example: false
        },
        error: %Schema{
          type: :object,
          description: "Error details",
          properties: %{
            code: %Schema{type: :string, enum: ["user_not_monitored"], example: "user_not_monitored"},
            message: %Schema{type: :string, example: "User is not being monitored by Lanyard"}
          },
          required: [:code, :message]
        }
      },
      required: [:success, :error],
    }
  end
end
