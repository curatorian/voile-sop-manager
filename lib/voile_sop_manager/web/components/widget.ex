defmodule VoileSopManager.Web.Components.Widget do
  @moduledoc """
  Dashboard widget component for SOP Manager statistics.
  """
  use Phoenix.LiveComponent

  import Phoenix.Component

  alias VoileSopManager.Sops

  @impl true
  def mount(socket) do
    counts = Sops.count_by_status()
    overdue = Sops.list_overdue_reviews()

    {:ok,
     socket
     |> assign(:active_count, Map.get(counts, "active", 0))
     |> assign(:draft_count, Map.get(counts, "draft", 0))
     |> assign(
       :review_count,
       Map.get(counts, "under_review", 0) + Map.get(counts, "pending_approval", 0)
     )
     |> assign(:overdue_count, length(overdue))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-2 gap-3">
      <div>
        <p class="text-2xl font-bold text-green-600"><%= @active_count %></p>
        <p class="text-xs text-gray-500">Active SOPs</p>
      </div>
      <div>
        <p class="text-2xl font-bold text-yellow-500"><%= @review_count %></p>
        <p class="text-xs text-gray-500">In Review</p>
      </div>
      <div>
        <p class="text-2xl font-bold text-gray-400"><%= @draft_count %></p>
        <p class="text-xs text-gray-500">Drafts</p>
      </div>
      <div>
        <p class={"text-2xl font-bold #{if @overdue_count > 0, do: "text-red-500", else: "text-gray-300"}"}>
          <%= @overdue_count %>
        </p>
        <p class="text-xs text-gray-500">Overdue Review</p>
      </div>
    </div>
    """
  end
end
