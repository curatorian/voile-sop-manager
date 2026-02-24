defmodule VoileSopManager.Migrator do
  @moduledoc """
  Migration runner for the SOP Manager plugin.
  Uses Voile's plugin migrator infrastructure.
  """
  use Voile.Plugin.Migrator, otp_app: :voile_sop_manager
end
