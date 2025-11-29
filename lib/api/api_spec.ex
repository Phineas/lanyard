defmodule Lanyard.ApiSpec do
  alias OpenApiSpex.{OpenApi, Info, PathItem, Contact, License, Components, SecurityScheme, Tag}

  alias Lanyard.Api.Doc.Operations.V1.Users, as: V1Users

  @spec spec() :: OpenApi.t()
  def spec do
    %OpenApi{
      info: %Info{
        title: "Lanyard RESTFul API",
        version: "1.0.0",
        description: "RESTful API documentation for Lanyard",
        contact: %Contact{
          name: "GitHub Repository",
          url: "https://github.com/Phineas/lanyard"
        },
        license: %License{
          name: "MIT License",
          url: "https://github.com/Phineas/lanyard/blob/main/LICENSE"
        }
      },
      components: %Components{
        schemas: %{},
        securitySchemes: %{
          "api_key" => %SecurityScheme{
            type: "apiKey",
            name: "authorization",
            in: "header",
            description: "**Getting an API Key**\n\nDM the Lanyard bot (`Lanyard#5766`) with `.apikey`.\n\n**Enter Key:**"
          }
        }
      },
      paths: %{
        "/v1/users/{user_id}/kv/{key}" => %PathItem{
          put: V1Users.set_kv(),
          delete: V1Users.delete_kv()
        },
        "/v1/users/{user_id}/kv" => %PathItem{
          patch: V1Users.update_kv(),
        },
        "/v1/users/@me" => %PathItem{
          get: V1Users.get_me()
        },
        "/v1/users/{id}" => %PathItem{
          get: V1Users.get_user()
        }
      },
      tags: [
        %Tag{
          name: "v1",
          description: "Endpoints for API version 1"
        },
      ],
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
