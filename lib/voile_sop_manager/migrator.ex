defmodule VoileSopManager.Migrator do
  @compile {:no_warn_undefined, Voile.Repo}
  @moduledoc """
  Migration runner for the SOP Manager plugin.
  Provides migration functions that are called by Voile's plugin system at runtime.
  """

  require Logger

  @otp_app :voile_sop_manager

  @doc "Run all pending migrations for this plugin."
  def run do
    migrations_path = migrations_path()
    repo = Voile.Repo

    unless File.dir?(migrations_path) do
      Logger.info("[SopManager.Migrator] No migrations directory, skipping")
      :ok
    else
      case Ecto.Migrator.run(repo, migrations_path, :up, all: true) do
        versions when is_list(versions) -> {:ok, versions}
        _ -> :ok
      end
    end
  rescue
    e -> {:error, "Migration failed: #{Exception.message(e)}"}
  end

  @doc """
  Rollback all migrations for this plugin.
  WARNING: This drops plugin tables and destroys all plugin data.
  """
  def rollback do
    migrations_path = migrations_path()
    repo = Voile.Repo

    case Ecto.Migrator.run(repo, migrations_path, :down, all: true) do
      versions when is_list(versions) -> {:ok, versions}
      _ -> :ok
    end
  rescue
    e -> {:error, "Rollback failed: #{Exception.message(e)}"}
  end

  @doc "Returns true if all migrations for this plugin have been applied."
  def migrated? do
    migrations_path()
    |> then(&Ecto.Migrator.migrations(Voile.Repo, [&1]))
    |> Enum.all?(fn {status, _, _} -> status == :up end)
  end

  @doc "Returns list of {status, version, name} for all plugin migrations."
  def status do
    Ecto.Migrator.migrations(Voile.Repo, [migrations_path()])
  end

  # ── Private ────────────────────────────────────────────────────────────────

  defp migrations_path do
    case :code.priv_dir(@otp_app) do
      {:error, :bad_name} ->
        # Fallback for development - use relative path
        Path.join([File.cwd!(), "plugins", "voile_sop_manager", "priv", "migrations"])

      path ->
        Path.join(to_string(path), "migrations")
    end
  end
end
