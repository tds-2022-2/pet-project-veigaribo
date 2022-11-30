defmodule Web.Router do
  def routes() do
    [
      _: [
        {"/auth", Web.Resources.Auth, []},
        {"/users", Web.Resources.Users, []},
        {"/users/:user", Web.Resources.User, []},
        {"/records", Web.Resources.Records, []},
        {"/records/:record", Web.Resources.Record, []},
        {"/health", Web.Resources.Health, []}
      ]
    ]
  end
end
