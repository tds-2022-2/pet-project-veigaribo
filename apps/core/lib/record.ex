defmodule Core.Record do
  def store(username, score) do
    Storage.transaction(fn ->
      existing_user = Storage.get_user(username)
      id = UUID.uuid4(:hex)

      case existing_user do
        {:found, _user} -> upsert({id, username, score})
        _ -> {:error, :user_not_found}
      end
    end)
  end

  defp upsert({id, username, score}) do
    new_record = {id, username, score}
    Storage.save_record(new_record)

    {:ok, new_record}
  end

  def get() do
    Storage.transaction(fn ->
      Storage.get_records()
    end)
  end

  def get(id) do
    Storage.transaction(fn ->
      result = Storage.get_record(id)

      case result do
        {:found, record} -> {:ok, record}
        :not_found -> {:error, :not_found}
      end
    end)
  end

  def delete(id) do
    Storage.transaction(fn ->
      Storage.delete_record(id)
    end)
  end
end
