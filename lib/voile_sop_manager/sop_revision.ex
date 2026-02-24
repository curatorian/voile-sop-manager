defmodule VoileSopManager.SopRevision do
  @moduledoc """
  Ecto schema for SOP revision history snapshots.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "plugin_sop_manager_revisions" do
    field(:sop_id, :binary_id)
    field(:version_major, :integer)
    field(:version_minor, :integer)
    field(:content, :string)
    field(:change_summary, :string)
    field(:changed_by_id, :integer)
    field(:status_at_save, :string)

    timestamps(updated_at: false)
  end

  @doc """
  Changeset for creating revision snapshots.
  """
  def changeset(revision, attrs) do
    revision
    |> cast(attrs, [
      :sop_id,
      :version_major,
      :version_minor,
      :content,
      :change_summary,
      :changed_by_id,
      :status_at_save
    ])
    |> validate_required([:sop_id, :version_major, :version_minor])
  end
end
