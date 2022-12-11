defmodule Web.Resources.Record do
  @behaviour :cowboy_rest

  @impl :cowboy_rest
  def init(req, state) do
    {:cowboy_rest, req, state}
  end

  @impl :cowboy_rest
  def allowed_methods(req, state) do
    {["DELETE", "GET", "OPTIONS"], req, state}
  end

  @impl :cowboy_rest
  def is_authorized(req, state) do
    case :cowboy_req.method(req) do
      "GET" ->
        {true, req, state}

      _ ->
        is_authorized2(req, state)
    end
  end

  defp is_authorized2(req, state) do
    id = :cowboy_req.binding(:record, req)
    result = Core.Record.get(id)

    case result do
      {:ok, record} -> is_authorized3(req, state ++ [found_record: record], record)
      # will 404
      {:error, :not_found} -> {true, req, state}
    end
  end

  defp is_authorized3(req, state, {_id, username, _score}) do
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

  def provide(req, state) do
    case :cowboy_req.method(req) do
      "GET" -> get(req, state)
    end
  end

  @impl :cowboy_rest
  def resource_exists(req, state) do
    id = :cowboy_req.binding(:record, req)
    result = Core.Record.get(id)

    case result do
      {:ok, record} -> {true, req, state ++ [found_record: record]}
      {:error, :not_found} -> {false, req, state}
    end
  end

  def get(req, state) do
    in_state = List.keyfind(state, :found_record, 0)

    case in_state do
      nil -> :shouldnt_happen
      {:found_record, record} -> get2(req, state, record)
    end
  end

  defp get2(req, state, {id, username, score}) do
    response_map = %{"id" => id, "username" => username, "score" => score}
    response = Jason.encode!(response_map)

    {response, req, state}
  end

  @impl :cowboy_rest
  def delete_resource(req, state) do
    id = :cowboy_req.binding(:record, req)
    Core.Record.delete(id)
    {true, req, state}
  end
end
