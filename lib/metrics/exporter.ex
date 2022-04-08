defmodule Lanyard.Metrics.Exporter do
  @behaviour Plug
  import Plug.Conn

  path = "/metrics"
  registry = :lanyard_registry

  def init(_opts) do
  end

  def call(conn, _opts) do
    case conn.request_path do
      unquote(path) ->
        {content_type, scrape} = scrape_data(conn)

        conn
        |> put_resp_content_type(content_type, nil)
        |> send_resp(200, scrape)
        |> halt

      _ ->
        conn
    end
  end

  def scrape_data(conn) do
    [accept] = Plug.Conn.get_req_header(conn, "accept")

    format =
      :accept_header.negotiate(
        accept,
        [
          {:prometheus_text_format.content_type(), :prometheus_text_format},
          {:prometheus_protobuf_format.content_type(), :prometheus_protobuf_format}
        ]
      )

    {format.content_type, format.format(unquote(registry))}
  end
end
