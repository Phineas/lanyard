defmodule Lanyard.Api.Doc.Schemas.V1.NoPermission do
  alias OpenApiSpex.Schema

  @spec schema() :: OpenApiSpex.Schema.t()
  def schema do
    %Schema{
      title: "NoPermission",
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
            code: %Schema{type: :string, enum: ["no_permission"], example: "no_permission"},
            message: %Schema{type: :string, example: "You do not have permission to access this resource"}
          },
          required: [:code, :message]
        }
      },
      required: [:success, :error],
    }
  end
end
