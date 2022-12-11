defmodule Web.ServerWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    dispatch = :cowboy_router.compile(Web.Router.routes())
    port = Application.fetch_env!(:server_web, :port)

    children = [
      # Starts a worker by calling: ServerWeb.Worker.start_link(arg)
      # {ServerWeb.Worker, arg}
      %{
        id: :my_http_listener,
        start:
          {:cowboy, :start_clear,
           [:my_http_listener, [port: port], %{:env => %{:dispatch => dispatch}}]}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ServerWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def prep_stop(_state) do
    :cowboy.stop_listener(:my_http_listener)
  end
end
