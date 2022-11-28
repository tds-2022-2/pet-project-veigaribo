defmodule Web.Router do
  def routes() do
    [
      _: [
        {"/auth", Web.Resources.Auth, []},
        {"/users", Web.Resources.Users, []},
        {"/users/:user", Web.Resources.User, []},
        {"/health", Web.Resources.Health, []}
      ]
    ]
  end
end
