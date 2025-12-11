defmodule Lanyard.Api.Doc.Operations.V1.Users do
  alias OpenApiSpex.{Operation, Schema}

  alias Lanyard.Api.Doc.Schemas.V1.{KvValidationFailed, UserNotMonitored, NoPermission, InvalidKvValue, User}

  @spec update_kv() :: Operation.t()
  def update_kv do
    %Operation{
      summary: "Update Discord user's KV value (merge)",
      description: "The body **must be** keyvalue pair object with a ``maximum depth of 1``.",
      tags: ["v1"],
      security: [%{"api_key" => []}],
      parameters: [
        Operation.parameter(:user_id, :path, %Schema{type: :string}, "Discord User ID", required: true),
      ],
      requestBody: Operation.request_body(
        "Key-value pairs to merge",
        "application/json",
        %Schema{
          type: :object,
          properties: %{},
          additionalProperties: %Schema{
            type: :string,
            description: "Value must be a string with maximum depth of 1"
          },
          maxProperties: 512,
          example: %{
            "theme" => "dark",
            "language" => "en",
            "notifications" => "enabled"
          }
        }
      ),
      responses: %{
        204 => Operation.response("Success", nil, nil),
        401 => Operation.response("No Permission", "application/json", NoPermission),
        404 => Operation.response("KV Validation Failed or Invalid KV Value", "application/json", %Schema{oneOf: [KvValidationFailed, InvalidKvValue]})
      }
    }
  end

  @spec delete_kv() :: Operation.t()
  def delete_kv do
    %Operation{
      summary: "Delete a Discord user's KV value",
      tags: ["v1"],
       security: [
          %{"api_key" => []}
      ],
      parameters: [
        Operation.parameter(:user_id, :path, %Schema{type: :string}, "Discord User ID", required: true),

        Operation.parameter(:key, :path, %Schema{
          type: :string,
          description: "Key identifier"
        }, "Key", required: true)
      ],
      responses: %{
        204 => Operation.response("Success", nil, nil),
        401 => Operation.response("No Permission", "application/json", NoPermission),
      }
    }
  end

  @spec set_kv() :: Operation.t()
  def set_kv do
    %Operation{
      summary: "Set Discord user's KV value",
      description: "**Limits:**
      \n\n1. Keys and values can **only be strings**;
      \n\n2. Values can be **30,000 characters** maximum;
      \n\n3. Keys must be **alphanumeric (a-zA-Z0-9)** and **255 characters max length**;
      \n\n4. Your user can have a maximum of **512 key->value pairs linked**;",
      tags: ["v1"],
      security: [
          %{"api_key" => []}
      ],
      parameters: [
        Operation.parameter(:user_id, :path, %Schema{type: :string}, "Discord User ID", required: true),

        Operation.parameter(:key, :path, %Schema{
          type: :string,
          pattern: "^[a-zA-Z0-9]+$",
          maxLength: 255,
          description: "Key identifier (Alphanumeric only)"
        }, "Key", required: true)
      ],
      requestBody: Operation.request_body(
        "Value content",
        "text/plain",
        %Schema{
          type: :string,
          maxLength: 30000,
          example: "@nerma.now is the best"
        }
      ),
      responses: %{
        204 => Operation.response("Success", nil, nil),
        401 => Operation.response("No Permission", "application/json", NoPermission),
        404 => Operation.response("KV Validation Failed", "application/json", KvValidationFailed)
      }
    }
  end

  @spec get_me() :: Operation.t()
  def get_me do
    %Operation{
      summary: "Get information about yourself",
      tags: ["v1"],
      security: [
          %{"api_key" => []}
        ],
      responses: %{
        200 => Operation.response("Success", "application/json", User),
        401 => Operation.response("No Permission", "application/json", NoPermission),
        404 => Operation.response("User Not Monitored", "application/json", UserNotMonitored)
      }
    }
  end

  @spec get_user() :: Operation.t()
  def get_user do
    %Operation{
      summary: "Get user information by ID",
      tags: ["v1"],
      parameters: [
        Operation.parameter(:id, :path, %Schema{type: :string}, "Discord user ID", required: true)
      ],
      responses: %{
        200 => Operation.response("Success", "application/json", User),
        404 => Operation.response("User Not Monitored", "application/json", UserNotMonitored)
      }
    }
  end
end
