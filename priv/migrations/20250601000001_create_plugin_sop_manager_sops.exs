defmodule VoileSopManager.Migrations.CreateSops do
  use Ecto.Migration

  def change do
    create table(:plugin_sop_manager_sops, primary_key: false) do
      add :id,              :binary_id, primary_key: true
      add :code,            :string, null: false       # e.g. "NAT-COL-HAND-001"
      add :title,           :string, null: false
      add :department,      :string, null: false       # "collections", "conservation", etc.
      add :category,        :string                    # "handling", "digitization", etc.
      add :status,          :string, null: false, default: "draft"
      add :version_major,   :integer, null: false, default: 1
      add :version_minor,   :integer, null: false, default: 0
      add :content,         :text                      # Markdown body
      add :purpose,         :text                      # Markdown: purpose & scope section
      add :owner_id,        :integer                   # Soft ref to Voile user
      add :effective_date,  :date
      add :review_due_date, :date
      add :retired_at,      :naive_datetime
      add :superseded_by_id, :binary_id               # Points to replacement SOP id
      add :risk_level,      :string, default: "low"   # "low" | "medium" | "high"
      add :tags,            {:array, :string}, default: []

      timestamps()
    end

    create unique_index(:plugin_sop_manager_sops, [:code])
    create index(:plugin_sop_manager_sops, [:status])
    create index(:plugin_sop_manager_sops, [:department])
    create index(:plugin_sop_manager_sops, [:review_due_date])
    create index(:plugin_sop_manager_sops, [:owner_id])
  end
end
