defmodule Lanyard.Api.Routes.Legal do
  import Plug.Conn

  @last_updated "2026-06-11"

  @subtitle "Lanyard &mdash; public presence &amp; profile API for members of the Lanyard Discord server"

  @style """
    :root { color-scheme: dark; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      background: #0d0f12;
      color: #e6e8eb;
      line-height: 1.6;
    }
    main {
      max-width: 760px;
      margin: 0 auto;
      padding: 64px 24px 96px;
    }
    header {
      margin-bottom: 32px;
      padding-bottom: 16px;
      border-bottom: 1px solid #1f2329;
    }
    header h1 {
      margin: 0 0 8px;
      font-size: 28px;
      font-weight: 600;
    }
    header p {
      margin: 0;
      color: #8b9098;
      font-size: 14px;
    }
    header .updated {
      margin-top: 8px;
      color: #6c7178;
      font-size: 13px;
    }
    h2 {
      margin: 32px 0 12px;
      font-size: 18px;
      font-weight: 600;
      color: #f4f6f8;
    }
    p, li { color: #c4c8cd; font-size: 15px; }
    ul { padding-left: 20px; }
    a { color: #7aa7ff; text-decoration: none; }
    a:hover { text-decoration: underline; }
    footer {
      margin-top: 48px;
      padding-top: 16px;
      border-top: 1px solid #1f2329;
      color: #6c7178;
      font-size: 13px;
    }
  """

  @terms_body """
    <p>
      These terms cover your use of the <strong>Lanyard</strong> service &mdash;
      the public API and WebSocket at
      <a href="https://api.lanyard.rest">api.lanyard.rest</a> that exposes
      Discord presence, activity, and user-set key/value data for members of
      the <strong>Lanyard Discord server</strong>.
    </p>

    <h2>Scope</h2>
    <p>
      The Lanyard service only collects presence and activity for users who
      are members of the Lanyard Discord server. Presence and activity from
      any other Discord server you are in is never collected. If you are not
      a member of the Lanyard server, no data about you is collected or
      exposed by the service.
    </p>

    <h2>What the service does</h2>
    <ul>
      <li>Reads your Discord presence (online status, current game, Spotify, custom status, etc.) while you are a member of the Lanyard server.</li>
      <li>Exposes that presence, plus your Discord user ID, username, and avatar, through a public REST API and WebSocket keyed on your Discord user ID.</li>
      <li>Stores and serves user-set key/value (KV) entries that you create through bot commands, as part of the same public API.</li>
    </ul>

    <h2>Public exposure</h2>
    <p>
      The Lanyard API is, by design, publicly readable: anyone who knows
      your Discord user ID can query your presence, activity, and KV data
      through it. That public exposure is the purpose of the service.
      By participating &mdash; that is, by being a member of the Lanyard
      Discord server &mdash; you acknowledge and accept that this data is
      publicly available for the duration of your membership. KV entries
      you create are also public; do not put anything sensitive in them.
    </p>

    <h2>Using the service</h2>
    <p>
      Lanyard is provided as-is, with no guarantee of uptime, availability,
      or accuracy. Your use of the API is also subject to Discord's
      <a href="https://discord.com/terms">Terms of Service</a>.
    </p>

    <h2>Acceptable use</h2>
    <ul>
      <li>Do not abuse the API (excessive request rates, attempts to disrupt service).</li>
      <li>Do not use Lanyard data to harass, dox, or profile other users.</li>
      <li>Do not resell, license, or commercialize Lanyard data.</li>
      <li>Do not use Lanyard data to train machine learning or AI models.</li>
    </ul>

    <h2>Termination</h2>
    <p>
      We may restrict your access to the API or KV system at any time, for
      any reason, particularly for violations of these terms. Leaving the
      Lanyard Discord server stops further presence collection and removes
      user-set KV data (see the <a href="/privacy">Privacy Policy</a>).
    </p>

    <h2>Changes</h2>
    <p>
      These terms may be updated from time to time. Continued use of the
      service after changes constitutes acceptance of the updated terms.
    </p>
  """

  @privacy_body """
    <p>
      This policy describes what data the <strong>Lanyard</strong> service
      &mdash; the public presence and profile API at
      <a href="https://api.lanyard.rest">api.lanyard.rest</a> &mdash; processes
      for members of the <strong>Lanyard Discord server</strong>, why, and
      how long it is kept.
    </p>

    <h2>Scope of collection</h2>
    <p>
      Lanyard only collects presence and activity data while you are a
      member of the Lanyard Discord server, and only as reported by Discord
      to that server. Presence in other Discord servers you are in is never
      collected. If you are not a member of the Lanyard server, the service
      holds no data about you.
    </p>

    <h2>What we process</h2>
    <ul>
      <li>
        <strong>Profile fields</strong> &mdash; your Discord user ID,
        username, and avatar are read so the API can return them alongside
        your presence.
      </li>
      <li>
        <strong>Presence &amp; activity</strong> &mdash; while you are a
        member of the Lanyard Discord server, your online status and
        activities Discord exposes to that server (current game, Spotify
        track, custom status, etc.) are read so they can be served through
        the public REST API and WebSocket. Presence is only read from the
        Lanyard server &mdash; not from any other server you are in.
      </li>
      <li>
        <strong>User-set KV data</strong> &mdash; key/value entries you set
        yourself through bot commands are stored so the API can serve them
        back. KV entries are public, alongside the rest of your Lanyard
        profile.
      </li>
    </ul>

    <h2>How it's used</h2>
    <ul>
      <li>Powering the public Lanyard REST API and WebSocket.</li>
      <li>Letting you embed your presence on status sites, personal websites, dashboards, and other places of your choosing.</li>
    </ul>

    <h2>Sharing &amp; public exposure</h2>
    <p>
      Presence, activity, profile fields, and KV data exposed via the
      Lanyard API are publicly readable by anyone who knows your Discord
      user ID. That is the purpose of the service. We do not sell data
      and do not share it with third parties beyond what is required to
      run the service (Discord, Cloudflare). Because the API is public,
      we cannot control who consumes it once data has been served.
    </p>

    <h2>Retention &amp; deletion</h2>
    <p>
      Presence and activity data is ephemeral &mdash; it only exists while
      you are a member of the Lanyard server and connected to Discord, and
      is not retained as historical records. User-set KV data persists
      until you remove it or until you leave the Lanyard Discord server,
      at which point all data set by you or provided by you to the service
      is deleted.
    </p>

    <h2>Your choices</h2>
    <ul>
      <li>Leave the Lanyard Discord server to stop presence collection and clear any user-set data tied to your account.</li>
      <li>Adjust your Discord privacy settings to control what presence/activity Discord exposes to servers in the first place.</li>
      <li>Remove KV entries you've set via the bot at any time.</li>
      <li>Avoid putting sensitive information in KV entries, since they are publicly readable.</li>
    </ul>

    <h2>Contact</h2>
    <p>
      Questions about this policy can be raised in the Lanyard Discord server.
    </p>
  """

  def terms(conn) do
    render(conn,
      title: "Terms of Service",
      document_title: "Terms of Service — Lanyard",
      active_path: "/terms",
      body: @terms_body
    )
  end

  def privacy(conn) do
    render(conn,
      title: "Privacy Policy",
      document_title: "Privacy Policy — Lanyard",
      active_path: "/privacy",
      body: @privacy_body
    )
  end

  defp render(conn, opts) do
    conn
    |> put_resp_content_type("text/html; charset=utf-8")
    |> send_resp(200, page(opts))
  end

  defp page(opts) do
    """
    <!doctype html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>#{opts[:document_title]}</title>
      <style>#{@style}</style>
    </head>
    <body>
      <main>
        <header>
          <h1>#{opts[:title]}</h1>
          <p>#{@subtitle}</p>
          <p class="updated">Last updated: #{@last_updated}</p>
        </header>
        #{opts[:body]}
        #{footer(opts[:active_path])}
      </main>
    </body>
    </html>
    """
  end

  defp footer(active_path) do
    """
    <footer>
      #{link("/terms", "Terms", active_path)} &middot; #{link("/privacy", "Privacy", active_path)}
    </footer>
    """
  end

  defp link(href, label, active_path) when href == active_path, do: "<strong>#{label}</strong>"
  defp link(href, label, _active_path), do: ~s(<a href="#{href}">#{label}</a>)
end
