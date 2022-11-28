defmodule ServerWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :server_web,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :core],
      mod: {Web.ServerWeb.Application, []},
      env: [port: 8080, base_url: "http://localhost:8080/"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:core, in_umbrella: true},
      {:cowboy, "~> 2.9"},
      {:jason, "~> 1.4"}
    ]
  end
end
