defmodule Core.User do
  def register(username, password) do
    Storage.transaction(fn ->
      hash = :crypto.hash(:sha3_512, password)
      existing_user = Storage.get_user(username)

      case existing_user do
        {:found, _user} -> {:error, :user_already_exists}
        _ -> upsert({username, hash})
      end
    end)
  end

  def update(username, patch) do
    Storage.transaction(fn ->
      result = Storage.get_user(username)

      case result do
        {:found, {^username, password}} ->
          new_password = Map.get(patch, "password", password)

          new_user = {username, new_password}
          update(new_user)

        :not_found ->
          {:error, :not_found}
      end
    end)
  end

  def update({username, password}) do
    Storage.transaction(fn ->
      hash = :crypto.hash(:sha3_512, password)
      existing_user = Storage.get_user(username)

      case existing_user do
        {:found, _user} -> upsert({username, hash})
        _ -> {:error, :not_found}
      end
    end)
  end

  defp upsert({username, hash}) do
    new_user = {username, hash}
    Storage.save_user(new_user)
  end

  def get(username) do
    Storage.transaction(fn ->
      result = Storage.get_user(username)

      case result do
        {:found, user} -> {:ok, strip_password(user)}
        :not_found -> {:error, :not_found}
      end
    end)
  end

  def strip_password({username, _}) do
    {username, :redacted}
  end

  def delete(username) do
    Storage.transaction(fn ->
      username
      |> Storage.get_sessions_by_user()
      |> Enum.each(&Core.Auth.revoke/1)

      Storage.delete_user(username)
    end)
  end
end
