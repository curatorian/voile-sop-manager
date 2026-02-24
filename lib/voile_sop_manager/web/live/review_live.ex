defmodule VoileSopManager.Web.Live.ReviewLive do
  @moduledoc """
  LiveView for the SOP review queue - shows SOPs awaiting review and overdue reviews.
  """
  use Phoenix.LiveView

  import Phoenix.Component

  alias VoileSopManager.{Sops, Sop}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "SOP Review Queue")
     |> assign(:overdue, Sops.list_overdue_reviews())
     |> assign(:under_review, list_under_review())
     |> assign(:pending_approval, list_pending_approval())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white">📋 SOP Review Queue</h2>
        <.link navigate="/manage/plugins/sop_manager/"
               class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition">
          ← Back to List
        </.link>
      </div>

      <!-- Overdue Reviews Alert -->
      <div :if={@overdue != []} class="bg-red-50 border border-red-200 rounded-lg p-6">
        <h3 class="text-lg font-semibold text-red-800 mb-4">
          ⚠️ Overdue for Review (<%= length(@overdue) %>)
        </h3>
        <p class="text-red-600 text-sm mb-4">
          These active SOPs have passed their review due date and should be reviewed.
        </p>
        <div class="space-y-3">
          <div :for={sop <- @overdue} class="bg-white rounded-lg p-4 shadow-sm">
            <div class="flex items-start justify-between">
              <div>
                <p class="font-mono text-sm text-gray-500"><%= sop.code %></p>
                <.link navigate={"/manage/plugins/sop_manager/#{sop.id}"}
                       class="font-medium text-gray-900 hover:text-blue-600">
                  <%= sop.title %>
                </.link>
                <p class="text-sm text-gray-500 mt-1">
                  <%= sop.department %> · <%= Sop.version_string(sop) %>
                </p>
              </div>
              <div class="text-right">
                <p class="text-sm text-red-600 font-medium">
                  Due: <%= Date.to_string(sop.review_due_date) %>
                </p>
                <p class="text-xs text-gray-400">
                  <%= days_overdue(sop.review_due_date) %> days overdue
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Under Review -->
      <div :if={@under_review != []} class="bg-yellow-50 border border-yellow-200 rounded-lg p-6">
        <h3 class="text-lg font-semibold text-yellow-800 mb-4">
          🔍 Under Review (<%= length(@under_review) %>)
        </h3>
        <p class="text-yellow-700 text-sm mb-4">
          SOPs currently in the review process.
        </p>
        <div class="space-y-3">
          <div :for={sop <- @under_review} class="bg-white rounded-lg p-4 shadow-sm">
            <div class="flex items-start justify-between">
              <div>
                <p class="font-mono text-sm text-gray-500"><%= sop.code %></p>
                <.link navigate={"/manage/plugins/sop_manager/#{sop.id}"}
                       class="font-medium text-gray-900 hover:text-blue-600">
                  <%= sop.title %>
                </.link>
                <p class="text-sm text-gray-500 mt-1">
                  <%= sop.department %> · <%= Sop.version_string(sop) %>
                </p>
              </div>
              <div class="flex gap-2">
                <.link navigate={"/manage/plugins/sop_manager/#{sop.id}"}
                       class="px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700">
                  Review
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Pending Approval -->
      <div :if={@pending_approval != []} class="bg-purple-50 border border-purple-200 rounded-lg p-6">
        <h3 class="text-lg font-semibold text-purple-800 mb-4">
          📝 Pending Approval (<%= length(@pending_approval) %>)
        </h3>
        <p class="text-purple-700 text-sm mb-4">
          SOPs that have passed review and await final approval.
        </p>
        <div class="space-y-3">
          <div :for={sop <- @pending_approval} class="bg-white rounded-lg p-4 shadow-sm">
            <div class="flex items-start justify-between">
              <div>
                <p class="font-mono text-sm text-gray-500"><%= sop.code %></p>
                <.link navigate={"/manage/plugins/sop_manager/#{sop.id}"}
                       class="font-medium text-gray-900 hover:text-blue-600">
                  <%= sop.title %>
                </.link>
                <p class="text-sm text-gray-500 mt-1">
                  <%= sop.department %> · <%= Sop.version_string(sop) %> · Risk: <%= String.capitalize(sop.risk_level || "low") %>
                </p>
              </div>
              <div class="flex gap-2">
                <.link navigate={"/manage/plugins/sop_manager/#{sop.id}"}
                       class="px-3 py-1 bg-green-600 text-white text-sm rounded hover:bg-green-700">
                  Approve
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div :if={@overdue == [] and @under_review == [] and @pending_approval == []}
           class="bg-green-50 border border-green-200 rounded-lg p-8 text-center">
        <p class="text-green-700 text-lg font-medium">✅ All caught up!</p>
        <p class="text-green-600 text-sm mt-2">No SOPs currently require review or approval.</p>
      </div>

      <!-- Summary Stats -->
      <div class="grid grid-cols-3 gap-4">
        <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-4 text-center">
          <p class="text-3xl font-bold text-red-500"><%= length(@overdue) %></p>
          <p class="text-sm text-gray-500">Overdue</p>
        </div>
        <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-4 text-center">
          <p class="text-3xl font-bold text-yellow-500"><%= length(@under_review) %></p>
          <p class="text-sm text-gray-500">Under Review</p>
        </div>
        <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-4 text-center">
          <p class="text-3xl font-bold text-purple-500"><%= length(@pending_approval) %></p>
          <p class="text-sm text-gray-500">Pending Approval</p>
        </div>
      </div>
    </div>
    """
  end

  defp list_under_review do
    Sops.list_sops(status: "under_review")
  end

  defp list_pending_approval do
    Sops.list_sops(status: "pending_approval")
  end

  defp days_overdue(due_date) do
    Date.diff(Date.utc_today(), due_date)
  end
end
