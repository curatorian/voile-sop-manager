defmodule VoileSopManager.Web.Live.IndexLive do
  @moduledoc """
  LiveView for listing all SOPs with filtering and status overview.
  """
  use Phoenix.LiveView

  alias VoileSopManager.{Sops, Sop, Settings}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "SOP Manager")
     |> assign(:filter_status, nil)
     |> assign(:filter_department, nil)
     |> load_sops()
     |> assign(:status_counts, Sops.count_by_status())
     |> assign(:overdue, Sops.list_overdue_reviews())}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, params["status"])
     |> assign(:filter_department, params["department"])
     |> load_sops()}
  end

  @impl true
  def handle_event("filter", %{"status" => status, "department" => dept}, socket) do
    params = %{status: status, department: dept}
    {:noreply, push_patch(socket, to: ~p"/manage/plugins/sop_manager/?#{params}")}
  end

  @impl true
  def handle_event("clear_filter", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/manage/plugins/sop_manager/")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <h2 class="text-2xl font-bold text-gray-900 dark:text-white">📋 SOP Manager</h2>
        <.link navigate={~p"/manage/plugins/sop_manager/new"}
               class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition">
          + New SOP
        </.link>
      </div>

      <!-- Status summary pills -->
      <div class="flex gap-2 flex-wrap">
        <span :for={{status, count} <- @status_counts}
              phx-click="filter" phx-value-status={status} phx-value-department=""
              class={"cursor-pointer px-3 py-1 rounded-full text-sm font-medium #{status_pill_class(status)}"}>
          <%= status_label(status) %> (<%= count %>)
        </span>
      </div>

      <!-- Overdue review alert -->
      <div :if={@overdue != []}
           class="bg-amber-50 border border-amber-200 rounded-lg p-4 text-amber-800">
        ⚠️ <strong><%= length(@overdue) %> SOP(s)</strong> are overdue for review.
        <.link navigate={~p"/manage/plugins/sop_manager/review"} class="underline ml-2">
          View review queue →
        </.link>
      </div>

      <!-- SOP Table -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
          <thead class="bg-gray-50 dark:bg-gray-700">
            <tr>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Code</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Title</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Dept.</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Version</th>
              <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Review Due</th>
              <th class="px-6 py-3"></th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
            <tr :for={sop <- @sops} class="hover:bg-gray-50 dark:hover:bg-gray-700">
              <td class="px-6 py-4 text-sm font-mono text-gray-600"><%= sop.code %></td>
              <td class="px-6 py-4 text-sm font-medium text-gray-900 dark:text-white">
                <.link navigate={~p"/manage/plugins/sop_manager/#{sop.id}"}>
                  <%= sop.title %>
                </.link>
              </td>
              <td class="px-6 py-4 text-sm text-gray-500"><%= sop.department %></td>
              <td class="px-6 py-4">
                <span class={"px-2 py-1 text-xs rounded-full #{status_pill_class(sop.status)}"}>
                  <%= status_label(sop.status) %>
                </span>
              </td>
              <td class="px-6 py-4 text-sm text-gray-500"><%= Sop.version_string(sop) %></td>
              <td class="px-6 py-4 text-sm text-gray-500">
                <span class={if overdue?(sop), do: "text-red-600 font-semibold"}>
                  <%= format_date(sop.review_due_date) %>
                </span>
              </td>
              <td class="px-6 py-4 text-right">
                <.link navigate={~p"/manage/plugins/sop_manager/#{sop.id}/edit"}
                       class="text-sm text-blue-600 hover:underline">
                  Edit
                </.link>
              </td>
            </tr>
          </tbody>
        </table>

        <div :if={@sops == []} class="text-center py-12 text-gray-500">
          No SOPs found. <.link navigate={~p"/manage/plugins/sop_manager/new"} class="text-blue-600">Create the first one.</.link>
        </div>
      </div>
    </div>
    """
  end

  # ── Private helpers ──
  defp load_sops(socket) do
    sops =
      Sops.list_sops(
        status: socket.assigns[:filter_status],
        department: socket.assigns[:filter_department]
      )

    assign(socket, :sops, sops)
  end

  defp status_label("draft"), do: "Draft"
  defp status_label("under_review"), do: "Under Review"
  defp status_label("pending_approval"), do: "Pending Approval"
  defp status_label("active"), do: "Active"
  defp status_label("superseded"), do: "Superseded"
  defp status_label("retired"), do: "Retired"
  defp status_label("archived"), do: "Archived"
  defp status_label(s), do: s

  defp status_pill_class("draft"), do: "bg-gray-100 text-gray-700"
  defp status_pill_class("under_review"), do: "bg-yellow-100 text-yellow-800"
  defp status_pill_class("pending_approval"), do: "bg-purple-100 text-purple-800"
  defp status_pill_class("active"), do: "bg-green-100 text-green-700"
  defp status_pill_class("superseded"), do: "bg-orange-100 text-orange-700"
  defp status_pill_class("retired"), do: "bg-gray-200 text-gray-500"
  defp status_pill_class("archived"), do: "bg-gray-300 text-gray-600"
  defp status_pill_class(_), do: "bg-gray-100 text-gray-500"

  defp format_date(nil), do: "—"
  defp format_date(date), do: Date.to_string(date)

  defp overdue?(%{review_due_date: nil}), do: false

  defp overdue?(%{review_due_date: d, status: "active"}),
    do: Date.compare(d, Date.utc_today()) == :lt

  defp overdue?(_), do: false
end
