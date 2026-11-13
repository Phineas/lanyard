defmodule Lanyard.Api.Routes.V1.UsersTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  alias Lanyard.Api.Routes.V1.Users
  alias Lanyard.KV.Interface
  alias Lanyard.Presence

  @user_id "123456789012345678"
  @body_limit 8_000_000

  # Only the external Redis process is replaced; routing, validation, and presence
  # updates run through the production modules without a Discord connection.
  defmodule RedisStub do
    use GenServer

    def start_link(keys), do: GenServer.start_link(__MODULE__, keys, name: :local_redis_client)

    @impl true
    def init(keys), do: {:ok, keys}

    @impl true
    def handle_call({:get, "api_key:" <> key}, _from, keys), do: {:reply, {:ok, Map.get(keys, key)}, keys}
    def handle_call({:hgetall, _key}, _from, keys), do: {:reply, {:ok, []}, keys}

    @impl true
    def handle_cast(_message, keys), do: {:noreply, keys}
  end

  defmodule BodyAdapter do
    def read_req_body(%{read_result: result, owner: owner} = state, _opts) do
      send(owner, :body_read)

      case result do
        {status, body} when status in [:ok, :more] -> {status, body, state}
        {:error, reason} -> {:error, reason}
      end
    end

    defdelegate send_resp(state, status, headers, body), to: Plug.Adapters.Test.Conn
  end

  setup do
    start_supervised!({RedisStub, %{"valid" => @user_id, "unmonitored" => "999"}})
    :ets.new(:cached_presences, [:named_table, :set, :public])
    :ets.new(:global_subscribers, [:named_table, :set, :public])
    :ets.new(Presence, [:named_table, :set, :public])

    presence =
      start_supervised!(
        {Presence, %Presence{user_id: @user_id, discord_user: %{"id" => @user_id}, discord_presence: nil}}
      )

    :ets.insert(Presence, {@user_id, presence})

    :ok
  end

  for {method, suffix} <- [{:patch, ""}, {:put, "/field"}] do
    describe "#{method} KV" do
      @method method
      @suffix suffix

      test "rejects missing authorization before reading the body" do
        response = request(@method, @suffix, {:more, ""}, nil)

        assert response.status == 401
        refute_received :body_read
      end

      test "rejects invalid authorization before reading the body" do
        response = request(@method, @suffix, {:more, ""}, "invalid")

        assert response.status == 401
        refute_received :body_read
      end

      test "rejects unmonitored users before reading the body" do
        response = request(@method, @suffix, {:more, ""}, "unmonitored", "999")

        assert response.status == 401
        refute_received :body_read
      end

      test "rejects a key belonging to a different user before reading the body" do
        response = request(@method, @suffix, {:more, ""}, "valid", "999")

        assert response.status == 401
        refute_received :body_read
      end

      test "returns 413 for an oversized partial body" do
        response = request(@method, @suffix, {:more, String.duplicate("x", @body_limit + 1)})

        assert_error(response, 413, "body_too_large")
      end

      test "returns 413 for an oversized complete body" do
        response = request(@method, @suffix, {:ok, String.duplicate("x", @body_limit + 1)})

        assert_error(response, 413, "body_too_large")
      end

      test "returns 408 for a partial body below the size limit" do
        response = request(@method, @suffix, {:more, "small body"})

        assert_error(response, 408, "request_timeout")
      end

      test "returns 408 for a partial body at the size limit" do
        response = request(@method, @suffix, {:more, String.duplicate("x", @body_limit)})

        assert_error(response, 408, "request_timeout")
      end

      test "returns 408 when the adapter reports a read timeout" do
        response = request(@method, @suffix, {:error, :timeout})

        assert_error(response, 408, "request_timeout")
      end

      test "returns 400 when the adapter reports another read error" do
        response = request(@method, @suffix, {:error, :closed})

        assert_error(response, 400, "invalid_body")
      end

      test "does not reject a complete body at the size limit as oversized" do
        body = if @method == :patch, do: ~s({"field":"value"}), else: "value"
        body = body <> String.duplicate(" ", @body_limit - byte_size(body))
        response = request(@method, @suffix, {:ok, body})

        if @method == :patch do
          assert response.status == 204
          assert Interface.get_all(@user_id) == %{"field" => "value"}
        else
          assert_error(response, 404, "kv_validation_failed")
        end
      end

      test "rejects an oversized body through Plug's test adapter" do
        response =
          conn(@method, "/#{@user_id}/kv#{@suffix}", String.duplicate("x", @body_limit + 1))
          |> put_req_header("authorization", "valid")
          |> Users.call(Users.init([]))

        assert_error(response, 413, "body_too_large")
      end
    end
  end

  test "PATCH rejects an empty KV key without changing the user's data" do
    response =
      conn(:patch, "/#{@user_id}/kv", ~s({"":"value"}))
      |> put_req_header("authorization", "valid")
      |> Users.call(Users.init([]))

    assert_error(response, 404, "kv_validation_failed")
    assert Interface.get_all(@user_id) == %{}
  end

  test "PATCH writes valid KV data through @me" do
    response =
      conn(:patch, "/@me/kv", ~s({"field":"value"}))
      |> put_req_header("authorization", "valid")
      |> Users.call(Users.init([]))

    assert response.status == 204
    assert Interface.get_all(@user_id) == %{"field" => "value"}
  end

  test "PUT writes valid KV data" do
    response =
      conn(:put, "/#{@user_id}/kv/field", "value")
      |> put_req_header("authorization", "valid")
      |> Users.call(Users.init([]))

    assert response.status == 204
    assert Interface.get_all(@user_id) == %{"field" => "value"}
  end

  defp request(method, suffix, result, key \\ "valid", user_id \\ @user_id) do
    conn = conn(method, "/#{user_id}/kv#{suffix}", "")
    {_, state} = conn.adapter
    conn = %{conn | adapter: {BodyAdapter, Map.put(state, :read_result, result)}}
    conn = if key, do: put_req_header(conn, "authorization", key), else: conn
    Users.call(conn, Users.init([]))
  end

  defp assert_error(response, status, code) do
    assert response.status == status
    assert %{"success" => false, "error" => %{"code" => ^code}} = Jason.decode!(response.resp_body)
  end
end
