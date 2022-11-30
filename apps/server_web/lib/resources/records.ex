defmodule Web.Resources.Records do
  @behaviour :cowboy_rest

  @impl :cowboy_rest
  def init(req, state) do
    {:cowboy_rest, req, state}
  end

  @impl :cowboy_rest
  def allowed_methods(req, state) do
    {["GET", "OPTIONS", "POST"], req, state}
  end

  @impl :cowboy_rest
  def is_authorized(req, state) do
    case :cowboy_req.method(req) do
      "GET" ->
        {true, req, state}

      _ ->
        result = Web.Auth.authenticate(req)

        case result do
          {:ok, session} -> {true, req, state ++ [session: session]}
          {:error, _} -> {{false, "Bearer"}, req, state}
        end
    end
  end

  @impl :cowboy_rest
  def content_types_accepted(req, state) do
    {
      [{{"application", "json", :*}, :accept}],
      req,
      state
    }
  end

  @impl :cowboy_rest
  def content_types_provided(req, state) do
    {
      [{{"application", "json", :*}, :provide}],
      req,
      state
    }
  end

  def accept(req, state) do
    case :cowboy_req.method(req) do
      "POST" -> post(req, state)
    end
  end

  def provide(req, state) do
    case :cowboy_req.method(req) do
      "GET" -> get(req, state)
    end
  end

  defp post(req, state) do
    {:ok, body, req1} = :cowboy_req.read_body(req)
    parse_result = Jason.decode(body, strings: :copy)

    case parse_result do
      {:ok, data} -> post2(req, state, data)
      {:error, _} -> {false, error_invalid_json(req1), state}
    end
  end

  defp post2(req, state, data) do
    case data do
      %{"score" => score} -> post3(req, state, score)
      _ -> {false, error_invalid_data(req), state}
    end
  end

  defp post3(req, state, score) do
    {:session, {_id, username, _valid_until}} = List.keyfind(state, :session, 0)
    result = Core.Record.store(username, score)

    case result do
      {:ok, {id, ^username, ^score}} -> post4(req, state, id, username)
      {:error, reason} -> {false, error_store(req, reason), state}
    end
  end

  def post4(req, state, id, username) do
    req1 =
      %{"id" => id, "username" => username}
      |> Jason.encode!()
      |> :cowboy_req.set_resp_body(req)

    base_url = Application.fetch_env!(:server_web, :base_url)
    resource_url = Path.join([base_url, "/records/", id])
    {{:created, resource_url}, req1, state}
  end

  defp get(req, state) do
    records = Core.Record.get()
    get2(req, state, records)
  end

  defp get2(req, state, records) do
    response =
      records
      |> Enum.map(fn {id, username, score} ->
        %{"id" => id, "username" => username, "score" => score}
      end)
      |> Jason.encode!()

    {response, req, state}
  end

  defp error_invalid_json(req) do
    map = %{"error" => "Invalid JSON."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end

  defp error_invalid_data(req) do
    map = %{"error" => "Invalid data. Expected username and score."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end

  defp error_store(req, :user_not_found) do
    map = %{"error" => "User not found."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end
end
