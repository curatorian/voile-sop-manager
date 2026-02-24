defmodule VoileSopManager.Web.Live.EditorLive do
  @moduledoc """
  LiveView for creating and editing SOPs with EasyMDE markdown editor.
  """
  use Phoenix.LiveView

  import Phoenix.Component

  alias VoileSopManager.{Sop, Sops, Settings}

  @impl true
  def mount(params, session, socket) do
    user_id = get_in(session, ["user_id"]) || 1

    {sop, action} =
      case params do
        %{"id" => id} -> {Sops.get_sop!(id), :edit}
        _ -> {%Sop{}, :new}
      end

    changeset = Sop.changeset(sop, %{})

    {:ok,
     socket
     |> assign(:sop, sop)
     |> assign(:action, action)
     |> assign(:user_id, user_id)
     |> assign(:changeset, changeset)
     |> assign(:page_title, if(action == :new, do: "New SOP", else: "Edit SOP"))}
  end

  @impl true
  def handle_event("save", %{"sop" => sop_params}, socket) do
    %{sop: sop, action: action, user_id: user_id} = socket.assigns

    result =
      if action == :new do
        Sops.create_sop(sop_params, user_id)
      else
        Sops.update_sop(sop, sop_params, user_id)
      end

    case result do
      {:ok, saved_sop} ->
        {:noreply,
         socket
         |> put_flash(:info, "SOP saved successfully.")
         |> push_navigate(to: "/manage/plugins/sop_manager/#{saved_sop.id}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("validate", %{"sop" => sop_params}, socket) do
    changeset =
      socket.assigns.sop
      |> Sop.changeset(sop_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">
        <%= if @action == :new, do: "📋 New SOP", else: "✏️ Edit SOP" %>
      </h2>

      <.form for={@changeset} phx-submit="save" phx-change="validate" class="space-y-6">

        <!-- Metadata row -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">SOP Code</label>
            <input type="text" name="sop[code]" value={@sop.code || ""}
                   placeholder="NAT-COL-HAND-001"
                   class="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" />
            <p class="mt-1 text-xs text-gray-500">Unique identifier for this SOP</p>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Department</label>
            <select name="sop[department]" class="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500">
              <%= for {label, value} <- department_options() do %>
                <option value={value} selected={@sop.department == value}><%= label %></option>
              <% end %>
            </select>
          </div>
          <div class="col-span-2">
            <label class="block text-sm font-medium text-gray-700">Title</label>
            <input type="text" name="sop[title]" value={@sop.title || ""}
                   placeholder="Handling Fragile Photographic Materials"
                   class="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Category</label>
            <select name="sop[category]" class="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500">
              <%= for {label, value} <- category_options() do %>
                <option value={value} selected={@sop.category == value}><%= label %></option>
              <% end %>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Risk Level</label>
            <select name="sop[risk_level]" class="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500">
              <option value="low" selected={@sop.risk_level == "low"}>Low</option>
              <option value="medium" selected={@sop.risk_level == "medium"}>Medium</option>
              <option value="high" selected={@sop.risk_level == "high"}>High</option>
            </select>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Effective Date</label>
            <input type="date" name="sop[effective_date]" value={format_date_field(@sop.effective_date)}
                   class="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">Review Due Date</label>
            <input type="date" name="sop[review_due_date]" value={format_date_field(@sop.review_due_date) || format_date_field(Settings.default_review_date())}
                   class="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" />
          </div>
        </div>

        <!-- Purpose & Scope (EasyMDE instance 1) -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Purpose & Scope</label>
          <div phx-hook="MarkdownEditor"
               id="editor-purpose"
               data-field-name="sop[purpose]"
               data-initial-value={@sop.purpose || ""}>
            <textarea name="sop[purpose]" id="editor-purpose-textarea"
                      class="hidden"><%= @sop.purpose %></textarea>
          </div>
        </div>

        <!-- Main content (EasyMDE instance 2) -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">SOP Content</label>
          <p class="text-xs text-gray-400 mb-2">
            Use Markdown. Structure with headings: ## Roles & Responsibilities, ## Procedure, ## Related Documents
          </p>
          <div phx-hook="MarkdownEditor"
               id="editor-content"
               data-field-name="sop[content]"
               data-initial-value={@sop.content || ""}>
            <textarea name="sop[content]" id="editor-content-textarea"
                      class="hidden"><%= @sop.content %></textarea>
          </div>
        </div>

        <!-- Tags -->
        <div>
          <label class="block text-sm font-medium text-gray-700">Tags (comma-separated)</label>
          <input type="text" name="sop[tags]" value={format_tags(@sop.tags)}
                 placeholder="handling, photographs, conservation"
                 class="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500" />
        </div>

        <div class="flex gap-3">
          <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition">
            Save Draft
          </button>
          <.link navigate="/manage/plugins/sop_manager/" class="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition">
            Cancel
          </.link>
        </div>
      </.form>
    </div>
    """
  end

  defp department_options do
    [
      {"Collections / Curatorial", "collections"},
      {"Conservation", "conservation"},
      {"Archives", "archives"},
      {"Library Services", "library"},
      {"Digital Services", "digital"},
      {"Public Programs", "public_programs"},
      {"Facilities & Security", "facilities"},
      {"Administration", "administration"}
    ]
  end

  defp category_options do
    [
      {"Handling", "handling"},
      {"Digitization", "digitization"},
      {"Preservation", "preservation"},
      {"Access", "access"},
      {"Storage", "storage"},
      {"Security", "security"},
      {"General", "general"}
    ]
  end

  defp format_date_field(nil), do: ""
  defp format_date_field(date), do: Date.to_string(date)

  defp format_tags(nil), do: ""
  defp format_tags([]), do: ""
  defp format_tags(tags) when is_list(tags), do: Enum.join(tags, ", ")
end
