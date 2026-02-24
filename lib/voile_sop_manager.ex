defmodule VoileSopManager do
  @moduledoc """
  SOP Manager Plugin for Voile - Full lifecycle management for Standard Operating Procedures.

  This plugin provides:
  - Markdown-based SOP authoring with EasyMDE editor
  - Review and approval workflow (Draft → Under Review → Pending Approval → Active)
  - Staff acknowledgement tracking
  - Complete revision history
  - Dashboard widget for SOP statistics
  """

  @behaviour Voile.Plugin

  @impl true
  def metadata do
    %{
      id: "sop_manager",
      name: "SOP Manager",
      version: "1.0.0",
      author: "Your Institution",
      description:
        "Full lifecycle management for Standard Operating Procedures. " <>
          "Author SOPs in Markdown, route through review and approval workflows, " <>
          "track staff acknowledgements, and maintain revision history.",
      license_type: :free,
      icon: "📋",
      tags: ["sop", "compliance", "workflow", "glam", "documentation"]
    }
  end

  @impl true
  def on_install do
    VoileSopManager.Migrator.run()
  end

  @impl true
  def on_activate, do: :ok

  @impl true
  def on_deactivate, do: :ok

  @impl true
  def on_uninstall do
    VoileSopManager.Migrator.rollback()
  end

  @impl true
  def on_update(_old, _new) do
    VoileSopManager.Migrator.run()
  end

  @impl true
  def hooks do
    [
      {:dashboard_widgets, &__MODULE__.add_widget/1}
    ]
  end

  @impl true
  def routes do
    [
      {"/", VoileSopManager.Web.Live.IndexLive, :index},
      {"/new", VoileSopManager.Web.Live.EditorLive, :new},
      {"/:id", VoileSopManager.Web.Live.ShowLive, :show},
      {"/:id/edit", VoileSopManager.Web.Live.EditorLive, :edit},
      {"/review", VoileSopManager.Web.Live.ReviewLive, :review}
    ]
  end

  @impl true
  def settings_schema do
    [
      %{
        key: :default_review_cycle_days,
        type: :integer,
        label: "Default Review Cycle (days)",
        default: 730,
        required: false
      },
      %{
        key: :require_acknowledgement,
        type: :boolean,
        label: "Require staff to acknowledge active SOPs",
        default: true
      },
      %{
        key: :institution_code,
        type: :string,
        label: "Institution Code (for SOP numbering, e.g. NAT)",
        default: "ORG",
        required: true
      },
      %{
        key: :notify_on_status_change,
        type: :boolean,
        label: "Send notifications on status changes",
        default: false
      }
    ]
  end

  @doc """
  Adds the SOP Manager widget to the dashboard.
  """
  def add_widget(widgets) do
    widget = %{
      key: :sop_manager_stats,
      title: "SOP Manager",
      component: VoileSopManager.Web.Components.Widget,
      priority: 40
    }

    widgets ++ [widget]
  end
end
