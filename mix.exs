defmodule VoileSopManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :voile_sop_manager,
      version: "1.0.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:voile, path: "../../"}
    ]
  end
end
