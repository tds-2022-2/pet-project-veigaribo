defmodule Storage do
  def start_link() do
    Task.start_link(&init/0)
  end

  def init() do
    nodes = [node()]

    # could already exist
    :mnesia.create_schema(nodes)

    :ok = :mnesia.start()

    # could already exist
    :mnesia.create_table(:users,
      attributes: [:username, :password]
    )

    # could already exist
    :mnesia.create_table(:sessions,
      attributes: [:id, :username, :valid_until],
      index: [:username]
    )

    # could already exist
    :mnesia.create_table(:records,
      attributes: [:id, :username, :score],
      index: [:username]
    )

    :ok = :mnesia.wait_for_tables([:users, :sessions, :records], :infinity)
  end

  def transaction(fun) do
    {:atomic, result} = :mnesia.transaction(fun)
    result
  end

  # password is supposed to be already obfuscated
  def save_user({username, password}) do
    :mnesia.write({:users, username, password})
  end

  def get_user(username) do
    result = :mnesia.read(:users, username)

    case result do
      [{:users, ^username, password}] -> {:found, {username, password}}
      _ -> :not_found
    end
  end

  def delete_user(username) do
    :mnesia.delete({:users, username})
  end

  def save_session({id, username, valid_until}) do
    :mnesia.write({:sessions, id, username, valid_until})
  end

  def get_session(id) do
    result = :mnesia.read(:sessions, id)

    case result do
      [{:sessions, ^id, username, valid_until}] -> {:found, {id, username, valid_until}}
      _ -> :not_found
    end
  end

  def get_sessions_by_user(username) do
    result = :mnesia.index_read(:sessions, username, :username)

    Enum.map(result, fn record ->
      {:sessions, id, ^username, valid_until} = record
      {id, username, valid_until}
    end)
  end

  def delete_session(id) do
    :mnesia.delete({:sessions, id})
  end

  def save_record({id, username, score}) do
    :mnesia.write({:records, id, username, score})
  end

  def get_record(id) do
    result = :mnesia.read(:records, id)

    case result do
      [{:records, ^id, username, score}] -> {:found, {id, username, score}}
      _ -> :not_found
    end
  end

  def get_records_by_user(username) do
    result = :mnesia.index_read(:records, username, :username)

    Enum.map(result, fn record ->
      {:records, id, ^username, score} = record
      {id, username, score}
    end)
  end

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
