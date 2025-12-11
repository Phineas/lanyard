defmodule Lanyard.Api.Doc.Schemas.V1.User do
  alias OpenApiSpex.Schema

  @spec schema() :: OpenApiSpex.Schema.t()
  def schema do
    spotify_schema = %Schema{
      type: :object,
      nullable: true,
      description: "Information about the track a Discord user is listening to",
      properties: %{
        track_id: %Schema{type: :string, example: "3kdlVcMVsSkbsUy8eQcBjI"},
        timestamps: %Schema{
          type: :object,
          properties: %{
            start: %Schema{type: :integer, format: :int64, example: 1615529820677},
            end: %Schema{type: :integer, format: :int64, example: 1615530068733}
          }
        },
        song: %Schema{type: :string, example: "Let Go"},
        artist: %Schema{type: :string, example: "Ark Patrol; Veronika Redd"},
        album_art_url: %Schema{type: :string, example: "https://i.scdn.co/image/ab67616d0000b27364840995fe43bb2ec73a241d"},
        album: %Schema{type: :string, example: "Let Go"},
      }
    }

    discord_user_schema = %Schema{
      type: :object,
      description: "User Discord Profile",
      properties: %{
        id: %Schema{type: :string, example: "94490510688792576"},
        username: %Schema{type: :string, example: "phin"},
        discriminator: %Schema{type: :string, example: "0"},
        avatar: %Schema{type: :string, example: "6b8c6a21ee4e549695f20c51036642e2"},
        global_name: %Schema{type: :string, example: "Phineas"},
        display_name: %Schema{type: :string, example: "Phineas"},
        bot: %Schema{type: :boolean, example: false},
        public_flags: %Schema{type: :integer, example: 131584},
        clan: %Schema{type: :object, nullable: true, example: nil},
        primary_guild: %Schema{type: :object, nullable: true, example: nil},
        avatar_decoration_data: %Schema{type: :object, nullable: true, example: nil},
        collectibles: %Schema{type: :object, nullable: true, example: nil},
        display_name_styles: %Schema{type: :object, nullable: true, example: nil}
      }
    }

     activity_schema = %Schema{
      type: :object,
      properties: %{
        id: %Schema{type: :string, example: "custom"},
        name: %Schema{type: :string, example: "Visual Studio Code"},
        type: %Schema{type: :integer, example: 4},
        state: %Schema{type: :string, nullable: true, example: "Workspace: lanyard"},
        details: %Schema{type: :string, nullable: true, example: "Editing README.md"},
        assets: %Schema{type: :object, nullable: true},
        timestamps: %Schema{type: :object, nullable: true},
        application_id: %Schema{type: :string, nullable: true, example: 383226320970055681}
      }
    }

    %Schema{
      title: "User",
      description: "Successful response with user data\n\n``May contain some inaccuracies, the returned data depends on the Discord API (https://discord.com/developers/docs/reference)``",
      type: :object,
      properties: %{
        success: %Schema{type: :boolean, enum: [true], example: true},
        data: %Schema{
          type: :object,
          properties: %{
            discord_status: %Schema{type: :string, enum: ["online", "idle", "dnd", "offline"], example: "offline"},
            active_on_discord_desktop: %Schema{type: :boolean, example: false},
            active_on_discord_mobile: %Schema{type: :boolean, example: false},
            active_on_discord_web: %Schema{type: :boolean, example: false},
            active_on_discord_embedded: %Schema{type: :boolean, example: false},
            listening_to_spotify: %Schema{type: :boolean, example: false},

            kv: %Schema{
              type: :object,
              description: "User Key-Value store",
              example: %{"location" => "Tokyo", "test" => "2", "waifu" => "mai sakurajima"},
              additionalProperties: %Schema{type: :string}
            },

            discord_user: discord_user_schema,
            spotify: spotify_schema,
            activities: %Schema{
              type: :array,
              items: activity_schema
            }
          }
        }
      },
      required: [:success, :data],
    }
  end
end
