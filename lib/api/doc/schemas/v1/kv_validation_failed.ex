defmodule Lanyard.Api.Doc.Schemas.V1.KvValidationFailed do
  alias OpenApiSpex.Schema

  @spec schema() :: OpenApiSpex.Schema.t()
  def schema do
    %Schema{
      title: "KvValidationFailed",
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
            code: %Schema{type: :string, enum: ["kv_validation_failed"], example: "kv_validation_failed"},
            message: %Schema{type: :string,
            enum: ["key must be 255 characters or less", "key must be alphanumeric (a-zA-Z0-9_)", "value must be 30000 characters or less",
            "request would exceed key limit (512), please delete keys first"],
            example: "key must be alphanumeric (a-zA-Z0-9_)"}
          },
          required: [:code, :message]
        }
      },
      required: [:success, :error],
    }
  end
end
