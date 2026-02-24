defmodule VoileSopManager.Migrations.CreateAcknowledgements do
  use Ecto.Migration

  def change do
    create table(:plugin_sop_manager_acknowledgements, primary_key: false) do
      add :id,              :binary_id, primary_key: true
      add :sop_id,          :binary_id, null: false
      add :user_id,         :integer, null: false
      add :acknowledged_at, :naive_datetime, null: false
      add :version_major,   :integer                   # Which version they acknowledged
      add :version_minor,   :integer

      timestamps(updated_at: false)
    end

    create unique_index(:plugin_sop_manager_acknowledgements, [:sop_id, :user_id])
    create index(:plugin_sop_manager_acknowledgements, [:sop_id])
    create index(:plugin_sop_manager_acknowledgements, [:user_id])
  end
end
