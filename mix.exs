defmodule VoileSopManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :voile_sop_manager,
      version: "1.0.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_deps: :apps_direct,
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {VoileSopManager.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.0"},
      {:ecto_sql, "~> 3.12"},
      # Server-side Markdown → HTML rendering
      {:mdex, "~> 0.2"},
      # dialyxir brings the `mix dialyzer` task and is only needed during development
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false}
      # Note: Don't add {:voile, path: "../../"} here - it creates a circular dependency.
      # The plugin is loaded by the main Voile project, so all Voile modules are already available.
    ]
  end
end
