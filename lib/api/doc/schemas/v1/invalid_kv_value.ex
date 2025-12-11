defmodule Lanyard.Api.Doc.Schemas.V1.InvalidKvValue do
  alias OpenApiSpex.Schema

  @spec schema() :: OpenApiSpex.Schema.t()
  def schema do
    %Schema{
      title: "InvalidKvValue",
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
            code: %Schema{type: :string, enum: ["invalid_kv_value"], example: "invalid_kv_value"},
            message: %Schema{type: :string, example: "body must be an object"}
          },
          required: [:code, :message]
        }
      },
      required: [:success, :error],
    }
  end
end
