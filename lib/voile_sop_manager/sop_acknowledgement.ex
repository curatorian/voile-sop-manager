defmodule VoileSopManager.SopAcknowledgement do
  @moduledoc """
  Ecto schema for SOP staff acknowledgement/read receipts.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "plugin_sop_manager_acknowledgements" do
    field(:sop_id, :binary_id)
    field(:user_id, :integer)
    field(:acknowledged_at, :naive_datetime)
    field(:version_major, :integer)
    field(:version_minor, :integer)

    timestamps(updated_at: false)
  end

  @doc """
  Changeset for creating acknowledgement records.
  """
  def changeset(ack, attrs) do
    ack
    |> cast(attrs, [:sop_id, :user_id, :acknowledged_at, :version_major, :version_minor])
    |> validate_required([:sop_id, :user_id, :acknowledged_at])
    |> unique_constraint([:sop_id, :user_id])
  end
end
