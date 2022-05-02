<img src="https://storage.googleapis.com/lanyard/static/lanyardtemplogo.png" alt="Lanyard Logo" width="300"/>

# 🏷️ Expose your Discord presence and activities to a RESTful API and WebSocket in less than 10 seconds

Lanyard is a service that makes it super easy to export your live Discord presence to an API endpoint (`api.lanyard.rest/v1/users/:your_id`) and to a WebSocket (see below) for you to use wherever you want - for example, I use this to display what I'm listening to on Spotify on my personal website. It also acts as a globally-accessible KV store which you can update from the Lanyard Discord bot or from the Lanyard API.

You can use Lanyard's API without deploying anything yourself - but if you want to self host it, you have the option to, though it'll require a tiny bit of configuration.

## Get started in < 10 seconds

Just [join this Discord server](https://discord.gg/UrXF2cfJ7F) and your presence will start showing up when you `GET api.lanyard.rest/v1/users/:your_id`. It's that easy.

## Table of Contents

- [Community Projects](#community-projects)
- [API Docs](#api-docs)
  - [Getting a user's presence data](#getting-a-user-s-presence-data)
  * [KV](#kv)
    - [Use cases](#use-cases)
    - [Limits](#limits)
    - [Getting an API Key](#getting-an-api-key)
    - [Setting a key->value pair](#setting-a-key--value-pair)
    - [Deleting a key](#deleting-a-key)
- [Socket Docs](#socket-docs)
  - [Subscribing to multiple user presences](#subscribing-to-multiple-user-presences)
  - [Subscribing to a single user presence](#subscribing-to-a-single-user-presence)
  - [Subscribing to every user presence](#subscribing-to-every-user-presence)
  * [List of Opcodes](#list-of-opcodes)
  * [Events](#events)
  * [Error Codes](#error-codes)
- [Quicklinks](#quicklinks)
- [Self-host with Docker](#self-host-with-docker)
- [Used By](#used-by)
- [Todo](#todo)

## Community Projects

The Lanyard community has worked on some pretty cool projects that allows you to extend the functionality of Lanyard. PR to add a project!

[lanyard-profile-readme](https://github.com/cnrad/lanyard-profile-readme) - Utilize Lanyard to display your Discord Presence in your GitHub Profile \
[spotsync.me](https://spotsync.me) - Stream music from your Discord presence to your friends in realtime through a slick UI \
[vue-lanyard](https://github.com/eggsy/vue-lanyard) - Lanyard API plugin for Vue. Supports REST and WebSocket methods \
[react-use-lanyard](https://github.com/barbarbar338/react-use-lanyard) - React hook for Lanyard - supports REST & WebSocket \
[use-lanyard](https://github.com/alii/use-lanyard) - Another React hook for Lanyard that uses SWR \
[lanyard-visualizer](https://lanyard-visualizer.netlify.app/) - Beautifully display your Discord presence on a website \
[hawser](https://github.com/5elenay/hawser) - Lanyard API wrapper for python. Supports both REST and WebSocket. \
[js-lanyard](https://github.com/xaronnn/js-lanyard/) - Use Lanyard in your Web App. \
[go-lanyard](https://github.com/barbarbar338/go-lanyard) - Lanyard API wrapper for GoLang - supports REST & WebSocket \
[use-lanyard](https://github.com/LeonardSSH/use-lanyard) - Lanyard with Composition API for Vue. Supports REST and WebSocket methods \
[use-listen-along](https://github.com/punctuations/use-listen-along) - Mock the discord 'Listen Along' feature within a react hook powered by the Lanyard API. \
[lanyard-graphql](https://github.com/DevSnowflake/lanyard-graphql) - A GraphQL port of the Lanyard API. \
[svelte-lanyard](https://github.com/iGalaxyYT/svelte-lanyard) - A Lanyard API wrapper for Svelte. Supports REST & WebSocket. \
[denyard](https://github.com/xHyroM/denyard) - Lanyard API wrapper for Deno - Supports REST & WebSocket. \
[lanyard-ui](https://lanyard.sakurajima.cloud/) - Lanyard visualizer focused on the KV aspect \
[discord-status-actions](https://github.com/CompeyDev/discord-status-action) - Updates a file to include your discord status using the Lanyard API.

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
    // Lanyard KV
    "kv": {
      "location": "Los Angeles, CA"
    },
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

### KV

Lanyard KV is a a dynamic, real-time key->value store which is added to the Lanyard user API response. When a KV pair is updated, a PRESENCE_UPDATE for the user will also be emitted through the Lanyard socket.

#### Use cases

- Configuration values for your website
- Configuration values for Lanyard 3rd party projects
- Dynamic data for your website/profile (e.g. current location)

#### Limits

1. Keys and values can only be strings
2. Values can be 30,000 characters maximum
3. Keys must be alphanumeric (a-zA-Z0-9) and 255 characters max length
4. Your user can have a maximum of 512 key->value pairs linked

#### Getting an API Key

DM the Lanyard bot (`Lanyard#5766`) with `.apikey` to get your API key.

When making Lanyard KV API requests, set an `Authorization` header with the API key you received from the Lanyard bot as the value.

#### Setting a key->value pair

##### Discord

`.set <key> <value>`

##### HTTP

`PUT https://api.lanyard.rest/v1/users/:user_id/kv/:key`  
The value will be set to the body of the request. The body can be any type of data, but it will be string-encoded when set in Lanyard KV.

#### Setting multiple key->value pairs

##### Discord

Not yet implemented

##### HTTP

`PATCH https://api.lanyard.rest/v1/users/:user_id/kv`  
The user's KV store will be merged with the body of the request. Conflicting keys will be overwritten. The body must be keyvalue pair object with a maximum depth of 1.

#### Deleting a key

##### Discord

`.del <key>`

##### HTTP

`DELETE https://api.lanyard.rest/v1/users/:user_id/kv/:key`

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

| Name                   | Code | Data                   |
| ---------------------- | ---- | ---------------------- |
| Invalid/Unknown Opcode | 4004 | `unknown_opcode`       |
| Opcode Requires Data   | 4005 | `requires_data_object` |
| Invalid Payload        | 4006 | `invalid_payload`      |

## Quicklinks

Lanyard quicklinks allow you to easily access resources from Discord, such as profile pictures.

### User Icons

`https://api.lanyard.rest/<id>.<file_type>`
Where `id` is the Discord user ID. `file_type` can be one of: `png`, `gif`, `webp`, `jpg`, or `jpeg`

## Self-host with Docker

Build the Docker image by cloning this repo and running:

```bash
# The latest version is already on the docker hub, you can skip this step unless you would like to run a modified version.
docker build -t phineas/lanyard:latest .
```

If you don't already have a redis server you'll need to run one, here's the docker command to run one:

```bash
docker run -d --name lanyard-redis -v docker_mount_location_on_host:/data redis
```

And run Lanyard API server using:

```bash
docker run --rm -it -p 4001:4001 -e REDIS_HOST=redis -e BOT_TOKEN=<token> --link lanyard-redis:redis phineas/lanyard:latest
```

You'll be able to access the API using **port 4001**.

You also need to create a Discord bot and use its token above.

Create a bot here: https://discord.com/developers/applications

**Make sure you enable** these settings in your bot settings:

- Privileged Gateway Intents > **PRESENCE INTENT**
- Privileged Gateway Intents > **SERVER MEMBERS INTENT**

If you'd like to run Lanyard with `docker-compose`, here's an example:

```yml
version: "3.8"

services:
  redis:
    image: redis
    restart: always
    container_name: lanyard_redis
  lanyard:
    image: phineas/lanyard:latest
    restart: always
    container_name: lanyard
    depends_on:
      - redis
    ports:
      - 4001:4001
    environment:
      BOT_TOKEN: <token>
      REDIS_HOST: redis
```

Note, that you're **hosting a http server, not https**. You'll need to use a **reverse proxy** such as [traefik](https://traefik.io/traefik/) if you want to secure your API endpoint.

## Used By

Below is a list of sites using Lanyard right now, check them out! A lot of them will only show an activity when they're active. Create a PR to add your site below!

- [alistair.cloud](https://alistair.cloud)
- [timcole.me](https://timcole.me)
- [dstn.to](https://dstn.to)
- [phineas.io](https://phineas.io)
- [slayter.dev](https://slayter.dev)
- [lafond.dev](https://lafond.dev)
- [cnrad.dev](https://cnrad.dev)
- [atzu.studio](https://atzu.studio)
- [dont-ping.me](https://dont-ping.me)
- [eggsy.xyz](https://eggsy.xyz)
- [crugg.de](https://crugg.de)
- [igalaxy.dev](https://igalaxy.dev)
- [itspolar.dev](https://itspolar.dev)
- [vasc.dev](https://vasc.dev)
- [eri.gg](https://eri.gg)
- [voided.dev](https://voided.dev)
- [thicc-thighs.de](https://thicc-thighs.de)
- [chezzer.dev](https://chezzer.dev)
- [arda.codes](https://arda.codes)
- [looskie.com](https://looskie.com)
- [barbarbar338.fly.dev](https://barbarbar338.fly.dev)
- [marino.codes](https://marino.codes)
- [stealthwave.dev](https://stealthwave.dev)
- [miraichu.co](https://miraichu.co)
- [nith.codes](https://nith.codes)
- [veny.xyz](https://veny.xyz)
- [5elenay.github.io](https://5elenay.github.io)
- [notnick.io](https://notnick.io)
- [encrypteddev.com](https://encrypteddev.com)
- [kevinthomas.codes](https://kevinthomas.codes)
- [amine.im](https://amine.im)
- [loom4k.me](https://loom4k.me)
- [presence.im](https://presence.im/)
- [eleven.codes](https://eleven.codes)
- [jackbailey.dev](https://jackbailey.dev)
- [345dev.me](https://345dev.me)
- [d3r1n.com](https://d3r1n.com/)
- [vops.cc](https://vops.cc)
- [lion.himbo.cat](https://lion.himbo.cat)
- [zeromomentum.me](https://zeromomentum.me)
- [emirkabal.com](https://emirkabal.com)
- [wosleyv.dev](https://www.wosleyv.dev)
- [aidan.pw](https://aidan.pw)
- [anaxes.codes](https://www.anaxes.codes)
- [avyanshralph.xyz](https://avyanshralph.xyz)
- [maki.cafe](https://maki.cafe)
- [cenap.js.org](https://cenap.js.org)
- [rexulec.com](https://rexulec.com)
- [isaackogan.com](https://www.isaackogan.com)
- [eleven011.xyz](https://eleven011.xyz)
- [krypton.ninja](https://krypton.ninja)
- [oxmc.xyz](https://oxmc.xyz)
- [voltages.me](https://voltages.me)
- [tysm.dev](https://tysm.dev)
- [ggorg.tk](https://ggorg.tk)
- [hexiaq.cf](https://hexiaq.cf)
- [itsdestiny.me](https://itsdestiny.me)
- [darkshiny.me](http://darkshiny.me)
- [nawrasse.vercel.app](https://nawrasse.vercel.app)
- [noirs.me](https://noirs.me)
- [2m4u.netlify.app](https://2m4u.netlify.app/)
- [eleven.js.org](https://eleven.js.org)
- [roxza.me](https://roxza.me)
- [keaton.codes](https://keaton.codes)
- [itsmebravo.dev](https://itsmebravo.dev)
- [cimok.co.uk](https://cimok.co.uk/)
- [winnerose.live](https://winnerose.live/)
- [alysum.vercel.app](https://alysum.vercel.app/)
- [alpha.is-a.dev](https://alpha.is-a.dev)
- [rovi.me](https://rovi.me)
- [snazzah.com](https://snazzah.com)

## Todo

- [ ] Landing page?
