defmodule Web.Resources.Auth do
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
      %{"username" => username, "password" => password} -> post3(req, state, username, password)
      _ -> {false, error_invalid_data(req), state}
    end
  end

  defp post3(req, state, username, password) do
    result = Core.Auth.login(username, password)

    case result do
      {:ok, session} -> post4(req, state, session)
      {:error, _} -> {false, error_login_failed(req), state}
    end
  end

  def post4(req, state, {id, _username, valid_until}) do
    response_map = %{"token" => id, "valid_until" => valid_until}
    response = Jason.encode!(response_map)

    req1 = :cowboy_req.set_resp_body(response, req)

    base_url = Application.fetch_env!(:server_web, :base_url)
    resource_url = Path.join(base_url, "/auth")
    {{:created, resource_url}, req1, state}
  end

  @impl :cowboy_rest
  def resource_exists(req, state) do
    result = Web.Auth.authenticate(req)

    case result do
      {:ok, user} -> {true, req, state ++ [found_user: user]}
      {:error, _} -> {false, req, state}
    end
  end

  defp get(req, state) do
    in_state = List.keyfind(state, :found_user, 0)

    case in_state do
      nil -> :shouldnt_happen
      {:found_user, user} -> get2(req, state, user)
    end
  end

  defp get2(req, state, {id, username, valid_until}) do
    response_map = %{"id" => id, "username" => username, "valid_until" => valid_until}
    response = Jason.encode!(response_map)

    {response, req, state}
  end

  defp error_invalid_json(req) do
    map = %{"error" => "Invalid JSON."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end

  defp error_invalid_data(req) do
    map = %{"error" => "Invalid data. Expected username and password."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end

  defp error_login_failed(req) do
    map = %{"error" => "Login failed (username or password invalid)."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end
end
