defmodule Web.Auth do
  def authenticate(req) when is_map(req) do
    authorization = :cowboy_req.header("authorization", req, :missing)

    case authorization do
      :missing -> {:error, :missing_token}
      token -> authenticate(token)
    end
  end

  def authenticate(authorization) when is_binary(authorization) do
    [type, value] = String.split(authorization, " ")

    case String.downcase(type) do
      "bearer" -> authenticate2(value)
      _ -> {:error, :invalid_authorization_type}
    end
  end

  defp authenticate2(token) do
    result = Core.Auth.validate_session(token)

    # for clarity
    case result do
      {:ok, session} -> {:ok, session}
      {:error, reason} -> {:error, reason}
    end
  end

  def is_user(req, username) do
    result = authenticate(req)

    case result do
      {:ok, session} ->
        {_id, username1, _valid_until} = session
        {:ok, session, username == username1}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
