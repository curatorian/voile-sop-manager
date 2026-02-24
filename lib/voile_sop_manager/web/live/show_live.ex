defmodule VoileSopManager.Web.Live.ShowLive do
  @moduledoc """
  LiveView for viewing SOP details with status transitions and acknowledgement.
  """
  use Phoenix.LiveView

  import Phoenix.HTML
  import Phoenix.Component

  alias VoileSopManager.{Sop, Sops, Acknowledgements}

  @impl true
  def mount(%{"id" => id}, session, socket) do
    user_id = get_in(session, ["user_id"]) || 1
    sop = Sops.get_sop!(id)
    revisions = Sops.list_revisions(id)
    acknowledged = Acknowledgements.acknowledged?(sop, user_id)
    ack_count = Acknowledgements.count_acknowledged(id)

    {:ok,
     socket
     |> assign(:sop, sop)
     |> assign(:revisions, revisions)
     |> assign(:user_id, user_id)
     |> assign(:acknowledged, acknowledged)
     |> assign(:ack_count, ack_count)
     |> assign(:page_title, sop.title)}
  end

  @impl true
  def handle_event("transition", %{"to" => new_status}, socket) do
    sop = socket.assigns.sop

    case Sops.transition(sop, new_status) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(:sop, updated)
         |> put_flash(:info, "SOP moved to #{status_label(new_status)}.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  @impl true
  def handle_event("acknowledge", _params, socket) do
    %{sop: sop, user_id: user_id} = socket.assigns

    case Acknowledgements.acknowledge(sop.id, user_id, sop.version_major, sop.version_minor) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:acknowledged, true)
         |> assign(:ack_count, socket.assigns.ack_count + 1)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not save acknowledgement.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-6">

      <!-- Header -->
      <div class="flex items-start justify-between">
        <div>
          <p class="text-sm font-mono text-gray-500"><%= @sop.code %> · <%= Sop.version_string(@sop) %></p>
          <h1 class="text-3xl font-bold text-gray-900 dark:text-white mt-1"><%= @sop.title %></h1>
          <p class="text-sm text-gray-500 mt-1">
            <%= @sop.department %> · Risk: <%= String.capitalize(@sop.risk_level || "low") %>
          </p>
        </div>
        <span class={"px-3 py-1 rounded-full text-sm font-medium #{status_pill_class(@sop.status)}"}>
          <%= status_label(@sop.status) %>
        </span>
      </div>

      <!-- Action buttons based on status -->
      <div class="flex gap-2 flex-wrap">
        <.link :if={@sop.status == "draft"}
               navigate={"/manage/plugins/sop_manager/#{@sop.id}/edit"}
               class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition">
          Edit
        </.link>
        <button :if={@sop.status == "draft"}
                phx-click="transition" phx-value-to="under_review"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition">
          Submit for Review
        </button>
        <button :if={@sop.status == "under_review"}
                phx-click="transition" phx-value-to="pending_approval"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition">
          Pass Review → Approval
        </button>
        <button :if={@sop.status == "under_review"}
                phx-click="transition" phx-value-to="draft"
                class="px-4 py-2 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600 transition">
          Request Revisions
        </button>
        <button :if={@sop.status == "pending_approval"}
                phx-click="transition" phx-value-to="active"
                class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition">
          ✅ Approve & Publish
        </button>
        <button :if={@sop.status == "pending_approval"}
                phx-click="transition" phx-value-to="draft"
                class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition">
          Reject
        </button>
        <button :if={@sop.status == "active"}
                phx-click="transition" phx-value-to="under_review"
                class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition">
          Trigger Review
        </button>
        <button :if={@sop.status == "active"}
                phx-click="transition" phx-value-to="retired"
                data-confirm="Retire this SOP?"
                class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition">
          Retire
        </button>
        <.link navigate="/manage/plugins/sop_manager/"
               class="px-4 py-2 bg-gray-100 text-gray-600 rounded-lg hover:bg-gray-200 transition">
          ← Back to List
        </.link>
      </div>

      <!-- Acknowledge bar (only for active SOPs) -->
      <div :if={@sop.status == "active"}
           class="bg-blue-50 border border-blue-200 rounded-lg p-4 flex items-center justify-between">
        <div>
          <p class="text-blue-800 font-medium">Staff Acknowledgement</p>
          <p class="text-blue-600 text-sm"><%= @ack_count %> staff acknowledged this version</p>
        </div>
        <button :if={not @acknowledged}
                phx-click="acknowledge"
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition">
          I've Read This SOP ✓
        </button>
        <span :if={@acknowledged} class="text-green-600 font-medium">✅ Acknowledged</span>
      </div>

      <!-- Purpose & Scope -->
      <div :if={@sop.purpose} class="bg-gray-50 dark:bg-gray-800 rounded-lg p-6">
        <h2 class="text-lg font-semibold mb-3">Purpose & Scope</h2>
        <div phx-hook="MermaidRenderer" id={"sop-purpose-#{@sop.id}"} class="prose dark:prose-invert max-w-none">
          <%= raw(render_markdown(@sop.purpose)) %>
        </div>
      </div>

      <!-- Main Content -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <div phx-hook="MermaidRenderer" id={"sop-content-#{@sop.id}"} class="prose dark:prose-invert max-w-none">
          <%= raw(render_markdown(@sop.content || "_No content yet._")) %>
        </div>
      </div>

      <!-- Metadata -->
      <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-6">
        <h2 class="text-lg font-semibold mb-3">Metadata</h2>
        <dl class="grid grid-cols-2 gap-4 text-sm">
          <div>
            <dt class="text-gray-500">Category</dt>
            <dd class="font-medium"><%= @sop.category || "—" %></dd>
          </div>
          <div>
            <dt class="text-gray-500">Effective Date</dt>
            <dd class="font-medium"><%= format_date(@sop.effective_date) %></dd>
          </div>
          <div>
            <dt class="text-gray-500">Review Due Date</dt>
            <dd class="font-medium"><%= format_date(@sop.review_due_date) %></dd>
          </div>
          <div>
            <dt class="text-gray-500">Tags</dt>
            <dd class="font-medium">
              <span :for={tag <- (@sop.tags || [])} class="inline-block bg-gray-200 rounded px-2 py-1 text-xs mr-1">
                <%= tag %>
              </span>
              <span :if={@sop.tags == [] || is_nil(@sop.tags)}>—</span>
            </dd>
          </div>
        </dl>
      </div>

      <!-- Revision History -->
      <details class="bg-white dark:bg-gray-800 rounded-lg shadow">
        <summary class="px-6 py-4 font-medium cursor-pointer">
          Revision History (<%= length(@revisions) %>)
        </summary>
        <div class="px-6 pb-4">
          <table class="min-w-full text-sm">
            <thead>
              <tr class="text-gray-500 text-left">
                <th class="py-2">Version</th>
                <th class="py-2">Status</th>
                <th class="py-2">Summary</th>
                <th class="py-2">Date</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={rev <- @revisions} class="border-t border-gray-100">
                <td class="py-2 font-mono">v<%= rev.version_major %>.<%= rev.version_minor %></td>
                <td class="py-2"><%= rev.status_at_save %></td>
                <td class="py-2 text-gray-600"><%= rev.change_summary %></td>
                <td class="py-2 text-gray-400"><%= format_datetime(rev.inserted_at) %></td>
              </tr>
            </tbody>
          </table>
        </div>
      </details>

    </div>
    """
  end

  # Markdown rendering with Mermaid diagram support
  defp render_markdown(nil), do: ""

  defp render_markdown(content) do
    # First, extract and protect mermaid code blocks
    {content, mermaid_blocks} = extract_mermaid_blocks(content)

    # Convert markdown to HTML
    # In production, use MDEx: MDEx.to_html!(content)
    html =
      content
      |> convert_markdown_to_html()

    # Restore mermaid blocks with proper rendering tags
    restore_mermaid_blocks(html, mermaid_blocks)
  end

  # Extract mermaid code blocks and replace with placeholders
  defp extract_mermaid_blocks(content) do
    mermaid_regex = ~r/```mermaid\n([\s\S]*?)```/

    blocks =
      Regex.scan(mermaid_regex, content)
      |> Enum.with_index()
      |> Enum.map(fn {[_, code], index} -> {index, code} end)
      |> Map.new()

    replaced =
      Regex.replace(mermaid_regex, content, fn _, _ ->
        "MERMAID_PLACEHOLDER"
      end)

    {replaced, blocks}
  end

  # Restore mermaid blocks with proper rendering markup
  defp restore_mermaid_blocks(html, mermaid_blocks) do
    Enum.reduce(mermaid_blocks, html, fn {_index, code}, acc ->
      mermaid_html = """
      <div class="mermaid-diagram my-4 p-4 bg-gray-50 rounded-lg overflow-x-auto">
        <pre class="mermaid">#{String.trim(code)}</pre>
      </div>
      """

      String.replace(acc, "MERMAID_PLACEHOLDER", mermaid_html, global: false)
    end)
  end

  # Simple markdown to HTML conversion
  # In production, replace with MDEx.to_html!(content)
  defp convert_markdown_to_html(content) do
    content
    |> String.replace(~r/##\s*(.+)/, "<h2>\\1</h2>")
    |> String.replace(~r/###\s*(.+)/, "<h3>\\1</h3>")
    |> String.replace(~r/\*\*(.+?)\*\*/, "<strong>\\1</strong>")
    |> String.replace(~r/\*(.+?)\*/, "<em>\\1</em>")
    |> String.replace(~r/`([^`]+)`/, "<code class=\"bg-gray-100 px-1 rounded\">\\1</code>")
    |> String.replace(~r/\n\n/, "</p><p>")
    |> String.replace(~r/\n/, "<br>")
    |> then(&"<p>#{&1}</p>")
  end

  defp status_label("draft"), do: "Draft"
  defp status_label("under_review"), do: "Under Review"
  defp status_label("pending_approval"), do: "Pending Approval"
  defp status_label("active"), do: "Active"
  defp status_label("superseded"), do: "Superseded"
  defp status_label("retired"), do: "Retired"
  defp status_label("archived"), do: "Archived"
  defp status_label(s), do: s

  defp status_pill_class("active"), do: "bg-green-100 text-green-700"
  defp status_pill_class("draft"), do: "bg-gray-100 text-gray-700"
  defp status_pill_class("under_review"), do: "bg-yellow-100 text-yellow-800"
  defp status_pill_class("pending_approval"), do: "bg-purple-100 text-purple-800"
  defp status_pill_class("superseded"), do: "bg-orange-100 text-orange-700"
  defp status_pill_class("retired"), do: "bg-gray-200 text-gray-500"
  defp status_pill_class("archived"), do: "bg-gray-300 text-gray-600"
  defp status_pill_class(_), do: "bg-gray-200 text-gray-500"

  defp format_date(nil), do: "—"
  defp format_date(date), do: Date.to_string(date)

  defp format_datetime(datetime), do: NaiveDateTime.to_date(datetime)
end
