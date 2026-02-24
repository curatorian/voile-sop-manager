defmodule VoileSopManager.Sop do
  @moduledoc """
  Ecto schema for Standard Operating Procedures.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  @statuses ~w(draft under_review pending_approval active superseded retired archived)
  @risk_levels ~w(low medium high)
  @departments ~w(collections conservation archives library digital public_programs facilities administration)

  schema "plugin_sop_manager_sops" do
    field(:code, :string)
    field(:title, :string)
    field(:department, :string)
    field(:category, :string)
    field(:status, :string, default: "draft")
    field(:version_major, :integer, default: 1)
    field(:version_minor, :integer, default: 0)
    field(:content, :string)
    field(:purpose, :string)
    field(:owner_id, :integer)
    field(:effective_date, :date)
    field(:review_due_date, :date)
    field(:retired_at, :naive_datetime)
    field(:superseded_by_id, :binary_id)
    field(:risk_level, :string, default: "low")
    field(:tags, {:array, :string}, default: [])

    timestamps()
  end

  @doc """
  Standard changeset for creating and updating SOPs.
  """
  def changeset(sop, attrs) do
    sop
    |> cast(attrs, [
      :code,
      :title,
      :department,
      :category,
      :content,
      :purpose,
      :owner_id,
      :effective_date,
      :review_due_date,
      :risk_level,
      :tags
    ])
    |> validate_required([:code, :title, :department])
    |> validate_inclusion(:risk_level, @risk_levels)
    |> validate_inclusion(:department, @departments)
    |> unique_constraint(:code)
  end

  @doc """
  Changeset for status transitions only.
  """
  def status_changeset(sop, new_status) do
    sop
    |> change(status: new_status)
    |> validate_inclusion(:status, @statuses)
  end

  @doc """
  Returns a human-readable version string.
  """
  def version_string(%__MODULE__{version_major: maj, version_minor: min}),
    do: "v#{maj}.#{min}"

  @doc """
  Returns the list of valid statuses.
  """
  def statuses, do: @statuses

  @doc """
  Returns the list of valid risk levels.
  """
  def risk_levels, do: @risk_levels

  @doc """
  Returns the list of valid departments.
  """
  def departments, do: @departments
end
