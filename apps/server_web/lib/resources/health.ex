defmodule Web.Resources.Health do
  @behaviour :cowboy_rest

  @impl :cowboy_rest
  def init(req, state) do
    {:cowboy_rest, req, state}
  end

  @impl :cowboy_rest
  def allowed_methods(req, state) do
    {["OPTIONS", "GET"], req, state}
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
    {~S|{"status": "fine"}|, req, state}
  end
end
