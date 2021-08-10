<img src="https://storage.googleapis.com/lanyard/static/lanyardtemplogo.png" alt="Lanyard Logo" width="300"/>

# 🏷️ Expose your Discord presence and activities to a RESTful API and WebSocket in less than 10 seconds

Lanyard is a service that makes it super easy to export your live Discord presence to an API endpoint (`api.lanyard.rest/v1/users/:your_id`) and to a WebSocket (see below) for you to use wherever you want - for example, I use this to display what I'm listening to on Spotify on my personal website.

You can use Lanyard's API without deploying anything yourself - but if you want to self host it, you have the option to, though it'll require a tiny bit of configuration.

## Get started in < 10 seconds

Just [join this Discord server](https://discord.gg/UrXF2cfJ7F) and your presence will start showing up when you `GET api.lanyard.rest/v1/users/:your_id`. It's that easy.

## Community Projects

The Lanyard community has worked on some pretty cool projects that allows you to extend the functionality of Lanyard. PR to add a project!

[lanyard-profile-readme](https://github.com/cnrad/lanyard-profile-readme) - Utilize Lanyard to display your Discord Presence in your GitHub Profile  
[spotsync.me](https://spotsync.me) - Stream music from your Discord presence to your friends in realtime through a slick UI  
[vue-lanyard](https://github.com/eggsy/vue-lanyard) - Lanyard API plugin for Vue. Supports REST and WebSocket methods  
[react-use-lanyard](https://github.com/barbarbar338/react-use-lanyard) - React hook for Lanyard - supports REST & WebSocket  
[use-lanyard](https://github.com/alii/use-lanyard) - Another React hook for Lanyard that uses SWR  
[lanyard-visualizer](https://lanyard-visualizer.netlify.app/) - Beautifully display your Discord presence on a website  
[hawser](https://github.com/5elenay/hawser) - Lanyard API wrapper for python. Supports both REST and WebSocket.  
[js-lanyard](https://github.com/xaronnn/js-lanyard/) - Use Lanyard in your Web App.  
[go-lanyard](https://github.com/barbarbar338/go-lanyard) - Lanyard API wrapper for GoLang - supports REST & WebSocket  

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
      "track_id": "3kdlVcMVsSkbsUy8eQcBjI",
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
      "id": "94490510688792576",
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

## Socket Docs

The websocket is available at `wss://api.lanyard.rest/socket`. If you would like to use compression, please specify `?compression=zlib_json` at the end of the URL.

Once connected, you will receive Opcode 1: Hello which will contain heartbeat_interval in the data field. You should set a repeating interval for the time specified in heartbeat_interval which should send Opcode 3: Heartbeat on the interval.

You should send `Opcode 2: Initialize` immediately after receiving Opcode 1.

Example of `Opcode 2: Initialize`:

```js
{
  op: 2,
  d: {
    // subscribe_to_ids should be an array of user IDs you want to subscribe to presences from
    // if Lanyard doesn't monitor an ID specified, it won't be included in INIT_STATE
    subscribe_to_ids: ["94490510688792576"]
  }
}
```

#### Subscribing to multiple user presences

To subscribe to multiple presences, send `subscribe_to_ids` in the data object with a `string[]` list of user IDs to subscribe to. Then, INIT_STATE's data object will contain a user_id->presence map. You can find examples below.

#### Subscribing to a single user presence

If you just want to subscribe to one user, you can send `subscribe_to_id` instead with a string of a single user ID to subscribe to. Then, the INIT_STATE's data will just contain the presence object for the user you've subscribed to instead of a user_id->presence map.

#### Subscribing to every user presence

If you want to subscribe to every presence being monitored by Lanyard, you can specify `subscribe_to_all` with (bool) `true` in the data object, and you will then receive a user_id->presence map with every user presence in INIT_STATE, and their respective PRESENCE_UPDATES when they happen.


Once Op 2 is sent, you should immediately receive an `INIT_STATE` event payload if connected successfully. If not, you will be disconnected with an error (see below).

### List of Opcodes

| Opcode | Name       | Description                                                                                                                 | Client Send/Recv |
| ------ | ---------- | --------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| 0      | Event      | This is the default opcode when receiving core events from Lanyard, like `INIT_STATE`                                       | Receive          |
| 1      | Hello      | Lanyard sends this when clients initially connect, and it includes the heartbeat interval                                   | Receive Only     |
| 2      | Initialize | This is what the client sends when receiving Opcode 1 from Lanyard - it should contain an array of user IDs to subscribe to | Send only        |
| 3      | Heartbeat  | Clients should send Opcode 3 every 30 seconds (or whatever the Hello Opcode says to heartbeat at)                           | Send only        |

### Events

Events are received on `Opcode 0: Event` - the event type will be part of the root message object under the `t` key.

#### Example Event Message Objects

#### `INIT_STATE`

```js
{
  op: 0,
  seq: 1,
  t: "INIT_STATE",
  d: {
    "94490510688792576": {
      // Full Lanyard presence (see API docs above for example)
    }
  }
}
```

#### `PRESENCE_UPDATE`

```js
{
  op: 0,
  seq: 2,
  t: "PRESENCE_UPDATE",
  d: {
    // Full Lanyard presence and an extra "user_id" field
  }
}
```

### Error Codes

Lanyard can disconnect clients for multiple reasons, usually to do with messages being badly formatted. Please refer to your WebSocket client to see how you should handle errors - they do not get received as regular messages.

#### Types of Errors

| Name                   | Code | Data             |
| ---------------------- | ---- | ---------------- |
| Invalid/Unknown Opcode | 4004 | `unknown_opcode` |

## Used By

Below is a list of sites using Lanyard right now, check them out! A lot of them will only show an activity when they're active. Create a PR to add your site below!

- [alistair.cloud](https://alistair.cloud)
- [timcole.me](https://timcole.me)
- [dustin.sh](https://dustin.sh)
- [phineas.io](https://phineas.io)
- [juan.engineer](https://juan.engineer)
- [slayter.dev](https://slayter.dev)
- [lafond.dev](https://lafond.dev)
- [atzu.studio](https://atzu.studio)
- [dont-ping.me](https://dont-ping.me)
- [astn.me](https://astn.me)
- [eggsy.xyz](https://eggsy.xyz)
- [crugg.de](https://crugg.de)
- [igalaxy.dev](https://igalaxy.dev)
- [itspolar.dev](https://itspolar.dev)
- [vasc.dev](https://vasc.dev)
- [eri.gg](https://eri.gg)
- [voided.dev](https://voided.dev)
- [thicc-thighs.de](https://thicc-thighs.de)
- [ademcancertel.tech](http://ademcancertel.tech)
- [chezzer.dev](https://chezzer.dev)
- [arda.codes](https://arda.codes)
- [looskie.com](https://looskie.com)
- [barbarbar338.fly.dev](https://barbarbar338.fly.dev)
- [marino.codes](https://marino.codes)
- [stealthwave.dev](https://stealthwave.dev)
- [miraichu.co](https://miraichu.co)
- [bobby.systems](https://bobby.systems/Core.Home)
- [dann.systems](https://dann.systems)
- [meric.vercel.app](https://meric.vercel.app)
- [spotsync.me](https://spotsync.me/?utm_source=lanyardgithub&utm_medium=link&utm_campaign=lanyard)
- [nith.codes](https://nith.codes)
- [callumdev.xyz](https://callumdev.xyz)
- [domm.me](https://domm.me)
- [rafstech.link](https://rafstech.link)
- [veny.xyz](https://veny.xyz)
- [5elenay.github.io](https://5elenay.github.io)
- [marcuscodes.me](https://marcuscodes.me)
- [nickdev.org](https://nickdev.org)
- [encrypteddev.com](https://encrypteddev.com)
- [kevinthomas.codes](https://kevinthomas.codes)
- [anaxes.xyz](https://anaxes.xyz)
- [amine.im](https://amine.im)
- [loom4k.me](https://loom4k.me)
- [katsie.xyz](https://katsie.xyz)

## Todo

- [ ] Landing page?
