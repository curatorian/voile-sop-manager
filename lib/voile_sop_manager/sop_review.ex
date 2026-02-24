defmodule VoileSopManager.SopReview do
  @moduledoc """
  Ecto schema for SOP review records.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  @decisions ~w(approved request_changes rejected)
  @reviewer_roles ~w(technical legal safety hr cross_department)

  schema "plugin_sop_manager_reviews" do
    field(:sop_id, :binary_id)
    field(:reviewer_id, :integer)
    field(:reviewer_role, :string)
    field(:decision, :string)
    field(:comments, :string)
    field(:reviewed_at, :naive_datetime)

    timestamps(updated_at: false)
  end

  @doc """
  Changeset for creating review records.
  """
  def changeset(review, attrs) do
    review
    |> cast(attrs, [:sop_id, :reviewer_id, :reviewer_role, :decision, :comments, :reviewed_at])
    |> validate_required([:sop_id, :reviewer_id, :decision])
    |> validate_inclusion(:decision, @decisions)
  end

  @doc """
  Returns the list of valid review decisions.
  """
  def decisions, do: @decisions

  @doc """
  Returns the list of valid reviewer roles.
  """
  def reviewer_roles, do: @reviewer_roles
end
