<img src="https://storage.googleapis.com/lanyard/static/lanyardtemplogo.png" alt="Lanyard Logo" width="300"/>

# Expose your Discord presence and activities to a RESTful API and WebSocket in less than 10 seconds

Lanyard is a service that makes it super easy to export your live Discord presence to an API endpoint (`api.lanyard.rest/v1/users/:your_id`) and to a WebSocket (see below) for you to use wherever you want - for example, I use this to display what I'm listening to on Spotify on my personal website.

You can use Lanyard's API without deploying anything yourself - but if you wan't to self host it, you have the option to, though it'll require a tiny bit of configuration.

## Get started in < 10 seconds

Just [join this Discord server](https://discord.gg/UrXF2cfJ7F) and your presence will start showing up when you `GET api.lanyard.rest/v1/users/:your_id`. It's that easy.

## API Docs
#### Getting a user's presence data
`GET https://api.lanyard.rest/v1/users/:user_id`

Example response:
```js
{
  "success": true,
  "data": {
    "active_on_discord_mobile": false,
    "active_on_discord_desktop": true,
    "listening_to_spotify": true,
    // Below is a custom crafted "spotify" object, which will be null if listening_to_spotify is false
    "spotify": {
      "timestamps": {
        "start": 1615529820677,
        "end": 1615530068733
      },
      "song": "Let Go",
      "artist": "Ark Patrol; Veronika Redd",
      "album_art_url": "https://i.scdn.co/image/ab67616d0000b27364840995fe43bb2ec73a241d",
      "album": "Let Go"
    },
    "discord_user": {
      "username": "Phineas",
      "public_flags": 131584,
      "id": 94490510688792576,
      "discriminator": "0001",
      "avatar": "a_7484f82375f47a487f41650f36d30318"
    },
    "discord_status": "online",
    // activities contains the plain Discord activities array that gets sent down with presences
    "activities": [
      {
        "type": 2,
        "timestamps": {
          "start": 1615529820677,
          "end": 1615530068733
        },
        "sync_id": "3kdlVcMVsSkbsUy8eQcBjI",
        "state": "Ark Patrol; Veronika Redd",
        "session_id": "140ecdfb976bdbf29d4452d492e551c7",
        "party": {
          "id": "spotify:94490510688792576"
        },
        "name": "Spotify",
        "id": "spotify:1",
        "flags": 48,
        "details": "Let Go",
        "created_at": 1615529838051,
        "assets": {
          "large_text": "Let Go",
          "large_image": "spotify:ab67616d0000b27364840995fe43bb2ec73a241d"
        }
      },
      {
        "type": 0,
        "timestamps": {
          "start": 1615438153941
        },
        "state": "Workspace: lanyard",
        "name": "Visual Studio Code",
        "id": "66b84f5317e9de6c",
        "details": "Editing README.md",
        "created_at": 1615529838050,
        "assets": {
          "small_text": "Visual Studio Code",
          "small_image": "565945770067623946",
          "large_text": "Editing a MARKDOWN file",
          "large_image": "565945077491433494"
        },
        "application_id": 383226320970055681
      }
    ]
  }
}
```

## Todo
- [ ] Finish WebSocket for subscribing to presences
- [ ] React component that makes it easy for people to embed their presence on a website
- [ ] Landing page?