defmodule VoileSopManager.Migrations.CreateReviews do
  use Ecto.Migration

  def change do
    create table(:plugin_sop_manager_reviews, primary_key: false) do
      add :id,              :binary_id, primary_key: true
      add :sop_id,          :binary_id, null: false
      add :reviewer_id,     :integer, null: false      # Soft ref to user
      add :reviewer_role,   :string                    # "technical", "legal", "safety"
      add :decision,        :string                    # "approved" | "request_changes" | "rejected"
      add :comments,        :text
      add :reviewed_at,     :naive_datetime

      timestamps(updated_at: false)
    end

    create index(:plugin_sop_manager_reviews, [:sop_id])
    create index(:plugin_sop_manager_reviews, [:reviewer_id])
  end
end
