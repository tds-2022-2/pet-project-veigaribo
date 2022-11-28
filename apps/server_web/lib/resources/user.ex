defmodule Web.Resources.User do
  @behaviour :cowboy_rest

  @impl :cowboy_rest
  def init(req, state) do
    {:cowboy_rest, req, state}
  end

  @impl :cowboy_rest
  def allowed_methods(req, state) do
    {["DELETE", "GET", "OPTIONS", "PATCH", "PUT"], req, state}
  end

  @impl :cowboy_rest
  def is_authorized(req, state) do
    username = :cowboy_req.binding(:user, req)
    result = Web.Auth.is_user(req, username)

    case result do
      {:ok, true} -> {true, req, state}
      {:ok, false} -> {{false, "Bearer"}, req, state}
      {:error, _} -> {{false, "Bearer"}, req, state}
    end
  end

  @impl :cowboy_rest
  def content_types_provided(req, state) do
    {
      [{{"application", "json", :*}, :provide}],
      req,
      state
    }
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
      "PUT" -> put(req, state)
      "PATCH" -> patch(req, state)
    end
  end

  def provide(req, state) do
    case :cowboy_req.method(req) do
      "GET" -> get(req, state)
    end
  end

  defp put(req, state) do
    {:ok, body, req1} = :cowboy_req.read_body(req)
    parse_result = Jason.decode(body, strings: :copy)

    case parse_result do
      {:ok, data} -> put2(req, state, data)
      {:error, _} -> {false, error_invalid_json(req1), state}
    end
  end

  defp put2(req, state, data) do
    case data do
      %{"username" => username, "password" => password} -> put3(req, state, username, password)
      _ -> {false, error_invalid_data(req), state}
    end
  end

  defp put3(req, state, username, password) do
    # check if the user in the url is the same as the one in the body
    bound_user = :cowboy_req.binding(:user, req)

    cond do
      username == bound_user -> put4(req, state, username, password)
      true -> {false, error_updating_different_user(req), state}
    end
  end

  def put4(req, state, username, password) do
    result = Core.User.update({username, password})

    case result do
      :ok -> {true, req, state}
      {:error, reason} -> {false, error_update(req, reason), state}
    end
  end

  def patch(req, state) do
    {:ok, body, req1} = :cowboy_req.read_body(req)
    parse_result = Jason.decode(body, strings: :copy)

    case parse_result do
      {:ok, data} -> patch2(req, state, data)
      {:error, _} -> {false, error_invalid_json(req1), state}
    end
  end

  defp patch2(req, state, data) do
    # check if the user in the url is the same as the one in the body
    new_username = Map.get(data, "username")
    bound_user = :cowboy_req.binding(:user, req)

    case new_username do
      nil -> patch3(req, state, bound_user, data)
      ^bound_user -> patch3(req, state, bound_user, data)
      _ -> {false, error_updating_different_user(req), state}
    end
  end

  def patch3(req, state, username, data) do
    result = Core.User.update(username, data)

    case result do
      :ok -> {true, req, state}
      {:error, reason} -> {false, error_update(req, reason), state}
    end
  end

  @impl :cowboy_rest
  def resource_exists(req, state) do
    username = :cowboy_req.binding(:user, req)
    result = Core.User.get(username)

    case result do
      {:ok, user} -> {true, req, state ++ [found_user: user]}
      {:error, :not_found} -> {false, req, state}
    end
  end

  defp get(req, state) do
    in_state = List.keyfind(state, :found_user, 0)

    case in_state do
      nil -> :shouldnt_happen
      {:found_user, user} -> get2(req, state, user)
    end
  end

  defp get2(req, state, {username, _password}) do
    response_map = %{"username" => username, "password" => nil}
    response = Jason.encode!(response_map)

    {response, req, state}
  end

  @impl :cowboy_rest
  def delete_resource(req, state) do
    username = :cowboy_req.binding(:user, req)
    Core.User.delete(username)
    {true, req, state}
  end

  defp error_invalid_json(req) do
    map = %{"error" => "Invalid JSON."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end

  defp error_invalid_data(req) do
    map = %{"error" => "Invalid data. Expected username and password."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end

  defp error_update(req, :not_found) do
    map = %{"error" => "An user with that name was not found."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end

  defp error_updating_different_user(req) do
    map = %{"error" => "Cannot update username."}
    :cowboy_req.set_resp_body(Jason.encode!(map), req)
  end
end
