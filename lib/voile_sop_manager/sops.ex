defmodule VoileSopManager.Sops do
  @moduledoc """
  Context module for SOP CRUD operations and status transitions.
  """

  import Ecto.Query
  alias Voile.Repo
  alias VoileSopManager.{Sop, SopRevision}

  # ── Queries ──────────────────────────────────────────────────────────────────

  @doc """
  Lists all SOPs with optional filtering by status and department.
  """
  def list_sops(filters \\ []) do
    query = from(s in Sop, order_by: [desc: s.inserted_at])

    query
    |> maybe_filter_status(filters[:status])
    |> maybe_filter_department(filters[:department])
    |> maybe_filter_overdue_review()
    |> Repo.all()
  end

  @doc """
  Gets a single SOP by ID.
  """
  def get_sop!(id), do: Repo.get!(Sop, id)

  @doc """
  Gets a single SOP by code.
  """
  def get_sop_by_code!(code), do: Repo.get_by!(Sop, code: code)

  @doc """
  Counts SOPs grouped by status.
  """
  def count_by_status do
    from(s in Sop, group_by: s.status, select: {s.status, count(s.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Lists all SOPs that are overdue for review.
  """
  def list_overdue_reviews do
    from(s in Sop,
      where: s.status == "active" and s.review_due_date <= ^Date.utc_today(),
      order_by: [asc: s.review_due_date]
    )
    |> Repo.all()
  end

  # ── CRUD ─────────────────────────────────────────────────────────────────────

  @doc """
  Creates a new SOP with an initial revision snapshot.
  """
  def create_sop(attrs, user_id) do
    Repo.transaction(fn ->
      case %Sop{} |> Sop.changeset(attrs) |> Repo.insert() do
        {:ok, sop} ->
          snapshot_revision(sop, user_id, "Initial draft")
          sop

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Updates an existing SOP and creates a revision snapshot.
  """
  def update_sop(%Sop{} = sop, attrs, user_id, change_summary \\ nil) do
    Repo.transaction(fn ->
      case sop |> Sop.changeset(attrs) |> Repo.update() do
        {:ok, updated_sop} ->
          # Bump minor version on content changes
          bumped = bump_minor_version(updated_sop)
          snapshot_revision(bumped, user_id, change_summary || "Content updated")
          bumped

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  # ── Status Transitions ───────────────────────────────────────────────────────

  @valid_transitions %{
    "draft" => ["under_review"],
    "under_review" => ["draft", "pending_approval"],
    "pending_approval" => ["draft", "active"],
    "active" => ["under_review", "retired", "superseded"],
    "superseded" => ["archived"],
    "retired" => ["archived"],
    "archived" => []
  }

  @doc """
  Transitions an SOP to a new status if the transition is valid.
  """
  def transition(%Sop{} = sop, new_status) do
    allowed = Map.get(@valid_transitions, sop.status, [])

    if new_status in allowed do
      sop
      |> Sop.status_changeset(new_status)
      |> maybe_set_retired_at(new_status)
      |> Repo.update()
    else
      {:error, "Transition from '#{sop.status}' to '#{new_status}' is not allowed"}
    end
  end

  @doc """
  Submits an SOP for review (draft → under_review).
  """
  def submit_for_review(%Sop{} = sop), do: transition(sop, "under_review")

  @doc """
  Requests revisions on an SOP (under_review → draft).
  """
  def request_revisions(%Sop{} = sop), do: transition(sop, "draft")

  @doc """
  Passes review and moves to pending approval (under_review → pending_approval).
  """
  def pass_review(%Sop{} = sop), do: transition(sop, "pending_approval")

  @doc """
  Rejects an SOP (pending_approval → draft).
  """
  def reject(%Sop{} = sop), do: transition(sop, "draft")

  @doc """
  Approves and publishes an SOP (pending_approval → active).
  Bumps major version on approval.
  """
  def approve(%Sop{} = sop) do
    Repo.transaction(fn ->
      {:ok, approved_sop} = transition(sop, "active")
      # Bump major version on approval
      bump_major_version(approved_sop) |> Repo.update!()
    end)
  end

  @doc """
  Triggers a review on an active SOP (active → under_review).
  """
  def trigger_review(%Sop{} = sop), do: transition(sop, "under_review")

  @doc """
  Retires an SOP (active → retired).
  """
  def retire(%Sop{} = sop), do: transition(sop, "retired")

  @doc """
  Archives an SOP (retired/superseded → archived).
  """
  def archive(%Sop{} = sop), do: transition(sop, "archived")

  @doc """
  Supersedes an old SOP with a new one.
  Marks the old SOP as superseded and approves the new one.
  """
  def supersede(%Sop{} = old_sop, %Sop{} = new_sop) do
    Repo.transaction(fn ->
      {:ok, _} = transition(old_sop, "superseded")
      Repo.update!(Ecto.Changeset.change(old_sop, superseded_by_id: new_sop.id))
      {:ok, approved} = approve(new_sop)
      approved
    end)
  end

  # ── Revision History ─────────────────────────────────────────────────────────

  @doc """
  Lists all revisions for a given SOP.
  """
  def list_revisions(sop_id) do
    from(r in SopRevision,
      where: r.sop_id == ^sop_id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  # ── Private Helpers ──────────────────────────────────────────────────────────

  defp snapshot_revision(sop, user_id, summary) do
    %SopRevision{}
    |> SopRevision.changeset(%{
      sop_id: sop.id,
      version_major: sop.version_major,
      version_minor: sop.version_minor,
      content: sop.content,
      change_summary: summary,
      changed_by_id: user_id,
      status_at_save: sop.status
    })
    |> Repo.insert!()
  end

  defp bump_minor_version(sop) do
    Ecto.Changeset.change(sop, version_minor: sop.version_minor + 1)
    |> Repo.update!()
  end

  defp bump_major_version(sop) do
    Ecto.Changeset.change(sop, version_major: sop.version_major + 1, version_minor: 0)
  end

  defp maybe_set_retired_at(changeset, "retired") do
    Ecto.Changeset.put_change(changeset, :retired_at, NaiveDateTime.utc_now())
  end

  defp maybe_set_retired_at(changeset, _), do: changeset

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [s], s.status == ^status)

  defp maybe_filter_department(query, nil), do: query
  defp maybe_filter_department(query, dept), do: where(query, [s], s.department == ^dept)

  # Opt-in via caller
  defp maybe_filter_overdue_review(query), do: query
end
