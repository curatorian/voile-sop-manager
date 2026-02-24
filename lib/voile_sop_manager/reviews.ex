defmodule VoileSopManager.Reviews do
  @moduledoc """
  Context module for SOP review workflow.
  """

  import Ecto.Query
  @compile {:no_warn_undefined, Voile.Repo}
  alias Voile.Repo
  alias VoileSopManager.{SopReview, Sop}

  @doc """
  Creates a new review record for an SOP.
  """
  def create_review(attrs) do
    %SopReview{}
    |> SopReview.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists all reviews for a specific SOP.
  """
  def list_reviews(sop_id) do
    from(r in SopReview,
      where: r.sop_id == ^sop_id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a specific review by ID.
  """
  def get_review!(id), do: Repo.get!(SopReview, id)

  @doc """
  Lists all pending reviews for a specific reviewer.
  """
  def list_pending_reviews_for_reviewer(reviewer_id) do
    from(r in SopReview,
      join: s in Sop,
      on: r.sop_id == s.id,
      where: r.reviewer_id == ^reviewer_id and is_nil(r.reviewed_at),
      select: {r, s},
      order_by: [asc: r.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Submits a review decision.
  """
  def submit_review(%SopReview{} = review, attrs) do
    review
    |> SopReview.changeset(Map.put(attrs, :reviewed_at, NaiveDateTime.utc_now()))
    |> Repo.update()
  end

  @doc """
  Counts reviews by decision type for an SOP.
  """
  def count_by_decision(sop_id) do
    from(r in SopReview,
      where: r.sop_id == ^sop_id and not is_nil(r.decision),
      group_by: r.decision,
      select: {r.decision, count(r.id)}
    )
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Checks if all required reviews are complete for an SOP.
  """
  def all_reviews_complete?(sop_id, required_roles \\ nil) do
    query =
      from(r in SopReview,
        where: r.sop_id == ^sop_id and not is_nil(r.reviewed_at)
      )

    query =
      if required_roles do
        where(query, [r], r.reviewer_role in ^required_roles)
      else
        query
      end

    completed_count = Repo.aggregate(query, :count)

    total_query = from(r in SopReview, where: r.sop_id == ^sop_id)

    total_query =
      if required_roles do
        where(total_query, [r], r.reviewer_role in ^required_roles)
      else
        total_query
      end

    total_count = Repo.aggregate(total_query, :count)

    completed_count == total_count and total_count > 0
  end
end
