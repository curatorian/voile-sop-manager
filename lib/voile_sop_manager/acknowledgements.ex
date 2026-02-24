defmodule VoileSopManager.Acknowledgements do
  @moduledoc """
  Context module for SOP staff acknowledgements/read receipts.
  """

  import Ecto.Query
  alias Voile.Repo
  alias VoileSopManager.SopAcknowledgement

  @doc """
  Records a staff acknowledgement for an SOP.
  Uses upsert to handle re-acknowledgements on new versions.
  """
  def acknowledge(sop_id, user_id, version_major, version_minor) do
    %SopAcknowledgement{}
    |> SopAcknowledgement.changeset(%{
      sop_id: sop_id,
      user_id: user_id,
      acknowledged_at: NaiveDateTime.utc_now(),
      version_major: version_major,
      version_minor: version_minor
    })
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:sop_id, :user_id])
  end

  @doc """
  Checks if a user has acknowledged a specific SOP.
  """
  def acknowledged?(%{id: sop_id}, user_id) do
    Repo.exists?(
      from(a in SopAcknowledgement,
        where: a.sop_id == ^sop_id and a.user_id == ^user_id
      )
    )
  end

  @doc """
  Counts the number of acknowledgements for an SOP.
  """
  def count_acknowledged(sop_id) do
    Repo.aggregate(
      from(a in SopAcknowledgement, where: a.sop_id == ^sop_id),
      :count
    )
  end

  @doc """
  Lists all acknowledgements for an SOP with user details.
  """
  def list_acknowledgements(sop_id) do
    from(a in SopAcknowledgement,
      where: a.sop_id == ^sop_id,
      order_by: [desc: a.acknowledged_at]
    )
    |> Repo.all()
  end

  @doc """
  Lists all SOPs acknowledged by a specific user.
  """
  def list_user_acknowledgements(user_id) do
    from(a in SopAcknowledgement,
      where: a.user_id == ^user_id,
      order_by: [desc: a.acknowledged_at]
    )
    |> Repo.all()
  end
end
