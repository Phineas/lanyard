<img src="https://storage.googleapis.com/lanyard/static/lanyardtemplogo.png" alt="Lanyard Logo" width="300"/>

## Expose your Discord presence and activities to a RESTful API and WebSocket in less than 10 seconds.

Lanyard is a service that makes it super easy to export your live Discord presence to an API endpoint (`api.lanyard.rest/v1/users/:your_id`) and to a WebSocket (see below) for you to use wherever you want - for example, I use this to display what I'm listening to on Spotify on my personal website.

### Get started in < 10 seconds

Just [join this Discord server](https://discord.gg/UrXF2cfJ7F) and your presence will start showing up when you `GET api.lanyard.rest/v1/users/:your_id`. It's that easy.

### API Docs
#### Getting a user's presence data
`GET https://api.lanyard.rest/v1/users/:user_id`

Example response:
```json
{
  "success": true,
  "data": {
    "spotify": {
      "timestamps": {
        "start": 1615529772305,
        "end": 1615529984377
      },
      "song": "Need You",
      "artist": "Kidswaste",
      "album_art_url": "https://i.scdn.co/image/ab67616d0000b2731fe8f7d34b0eb2e3f87571dd",
      "album": "Need You"
    },
    "listening_to_spotify": true,
    "discord_user": {
      "username": "Phineas",
      "public_flags": 131584,
      "id": 94490510688792576,
      "discriminator": "0001",
      "avatar": "a_7484f82375f47a487f41650f36d30318"
    },
    "discord_status": "online",
    "activities": [
      {
        "type": 2,
        "timestamps": {
          "start": 1615529772305,
          "end": 1615529984377
        },
        "sync_id": "6jilgLoqm0HI7zbdYaGFqG",
        "state": "Kidswaste",
        "session_id": "140ecdfb976bdbf29d4452d492e551c7",
        "party": {
          "id": "spotify:94490510688792576"
        },
        "name": "Spotify",
        "id": "spotify:1",
        "flags": 48,
        "details": "Need You",
        "created_at": 1615529816550,
        "assets": {
          "large_text": "Need You",
          "large_image": "spotify:ab67616d0000b2731fe8f7d34b0eb2e3f87571dd"
        }
      },
      {
        "type": 0,
        "timestamps": {
          "start": 1615503146651
        },
        "state": "Workspace: honk-server",
        "name": "Visual Studio Code",
        "id": "66b84f5317e9de6c",
        "details": "Editing chat.ts",
        "created_at": 1615529819828,
        "assets": {
          "small_text": "Visual Studio Code",
          "small_image": "565945770067623946",
          "large_text": "Editing a TYPESCRIPT file",
          "large_image": "808842276184784916"
        },
        "application_id": 383226320970055681
      }
    ],
    "active_on_discord_mobile": false,
    "active_on_discord_desktop": true
  }
}```