defmodule Core.Auth do
  def login(username, password) do
    Storage.transaction(fn ->
      hash = :crypto.hash(:sha3_512, password)
      user_result = Storage.get_user(username)

      case user_result do
        {:found, {^username, actual_hash}} ->
          if :crypto.hash_equals(hash, actual_hash) do
            do_login(username)
          else
            {:error, :password_doesnt_match}
          end

        _ ->
          {:error, :user_not_found}
      end
    end)
  end

  defp do_login(username) do
    username
    |> Storage.get_sessions_by_user()
    |> Enum.each(&revoke/1)

    id = UUID.uuid4(:hex)
    session_duration = Application.fetch_env!(:core, :session_duration_ms)
    valid_until = :os.system_time(:millisecond) + session_duration

    new_session = {id, username, valid_until}
    Storage.save_session(new_session)

    {:ok, new_session}
  end

  def logout(session_id) do
    revoke(session_id)
  end

  def revoke({id, _username, _valid_until}) do
    revoke(id)
  end

  def revoke(id) when is_binary(id) do
    Storage.transaction(fn ->
      Storage.delete_session(id)
    end)
  end

  def validate_session(session_id) do
    Storage.transaction(fn ->
      result = Storage.get_session(session_id)

      case result do
        {:found, session} -> validate(session)
        :not_found -> {:error, :not_found}
      end
    end)
  end

  defp validate(session) do
    {_id, _username, valid_until} = session
    now = :os.system_time(:millisecond)
    if valid_until < now, do: {:error, :expired}, else: {:ok, session}
  end

  def user_from_session({_id, username, valid_until}) do
    case validate(valid_until) do
      :expired ->
        :expired

      {:ok, _} ->
        {:ok, user} = Core.User.get(username)
        {:ok, user}
    end
  end

  def user_from_session(session_id) when is_binary(session_id) do
    Storage.transaction(fn ->
      result = Storage.get_session(session_id)

      case result do
        :not_found -> :not_found
        {:found, session} -> user_from_session(session)
      end
    end)
  end
end
