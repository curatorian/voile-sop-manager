defmodule VoileSopManager.Migrations.CreateRevisions do
  use Ecto.Migration

  def change do
    create table(:plugin_sop_manager_revisions, primary_key: false) do
      add :id,              :binary_id, primary_key: true
      add :sop_id,          :binary_id, null: false   # Soft ref to SOP
      add :version_major,   :integer, null: false
      add :version_minor,   :integer, null: false
      add :content,         :text                      # Snapshot of markdown at this version
      add :change_summary,  :string
      add :changed_by_id,   :integer                   # Soft ref to user
      add :status_at_save,  :string

      timestamps(updated_at: false)
    end

    create index(:plugin_sop_manager_revisions, [:sop_id])
  end
end
