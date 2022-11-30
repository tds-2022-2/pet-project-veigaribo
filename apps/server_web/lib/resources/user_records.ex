defmodule Web.Resources.UserRecords do
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
        username = :cowboy_req.binding(:user, req)
        result = Web.Auth.is_user(req, username)

        case result do
          {:ok, session, true} -> {true, req, state ++ [session: session]}
          {:ok, _session, false} -> {{false, "Bearer"}, req, state}
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

  def post(req, state) do
    Web.Resources.Records.post(req, state)
  end

  def get(req, state) do
    username = :cowboy_req.binding(:user, req)
    records = Core.Record.get_by_user(username)

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
end
