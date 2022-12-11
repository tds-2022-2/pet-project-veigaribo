defmodule Web.Resources.Users do
  @behaviour :cowboy_rest

  @impl :cowboy_rest
  def init(req, state) do
    {:cowboy_rest, req, state}
  end

  @impl :cowboy_rest
  def allowed_methods(req, state) do
    {["OPTIONS", "POST"], req, state}
  end

  @impl :cowboy_rest
  def content_types_accepted(req, state) do
    {
      [{{"application", "json", :*}, :accept}],
      req,
      state
    }
  end

  def accept(req, state) do
    case :cowboy_req.method(req) do
      "POST" -> post(req, state)
    end
  end

  def post(req, state) do
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
    cond do
      not is_binary(username) -> {false, error_username_not_string(req), state}
      not is_binary(password) -> {false, error_password_not_string(req), state}
      true -> post4(req, state, username, password)
    end
  end

  defp post4(req, state, username, password) do
    result = Core.User.register(username, password)

    case result do
      :ok -> post5(req, state, username)
      {:error, reason} -> {false, error_register(req, reason), state}
    end
  end

  defp post5(req, state, username) do
    base_url = Application.fetch_env!(:server_web, :base_url)
    resource_url = Path.join([base_url, "/users/", username])
    {{:created, resource_url}, req, state}
  end

  defp error_invalid_json(req) do
    map = %{"error" => "Invalid JSON."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end

  defp error_invalid_data(req) do
    map = %{"error" => "Invalid data. Expected username and password."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end

  defp error_username_not_string(req) do
    map = %{"error" => "Username must be a string."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end

  defp error_password_not_string(req) do
    map = %{"error" => "Password must be a string."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end

  defp error_register(req, :user_already_exists) do
    map = %{"error" => "An user with that name already exists."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end
end
