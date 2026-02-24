defmodule VoileSopManager.Settings do
  @moduledoc """
  Helper module for accessing SOP Manager plugin settings.
  """

  @plugin_id "sop_manager"
  @compile {:no_warn_undefined, Voile.Plugins}

  @doc """
  Gets a setting value by key, with an optional default.
  """
  def get(key, default \\ nil) do
    Voile.Plugins.get_plugin_setting(@plugin_id, key, default)
  end

  @doc """
  Sets a setting value by key.
  """
  def put(key, value) do
    Voile.Plugins.put_plugin_setting(@plugin_id, key, value)
  end

  @doc """
  Gets all settings for the plugin.
  """
  def get_all do
    case Voile.Plugins.get_plugin_by_plugin_id(@plugin_id) do
      nil -> %{}
      record -> record.settings || %{}
    end
  end

  @doc """
  Returns the default review cycle in days.
  """
  def review_cycle_days, do: get(:default_review_cycle_days, 730)

  @doc """
  Returns the institution code for SOP numbering.
  """
  def institution_code, do: get(:institution_code, "ORG")

  @doc """
  Returns whether staff acknowledgement is required.
  """
  def require_ack?, do: get(:require_acknowledgement, true)

  @doc """
  Returns whether notifications should be sent on status changes.
  """
  def notify_on_change?, do: get(:notify_on_status_change, false)

  @doc """
  Calculates the default review due date based on the review cycle setting.
  """
  def default_review_date do
    Date.utc_today()
    |> Date.add(review_cycle_days())
  end

  @doc """
  Returns the department abbreviation for SOP code generation.
  """
  def department_abbrev("collections"), do: "COL"
  def department_abbrev("conservation"), do: "CON"
  def department_abbrev("archives"), do: "ARC"
  def department_abbrev("library"), do: "LIB"
  def department_abbrev("digital"), do: "DIG"
  def department_abbrev("public_programs"), do: "PUB"
  def department_abbrev("facilities"), do: "FAC"
  def department_abbrev("administration"), do: "ADM"
  def department_abbrev(_), do: "XXX"

  @doc """
  Generates a new SOP code based on department and category.
  Format: {INSTITUTION_CODE}-{DEPT_CODE}-{CATEGORY_CODE}-{SEQ}
  Example: NAT-COL-HAND-001
  """
  def generate_sop_code(department, category, sequence) do
    inst = institution_code()
    dept = department_abbrev(department)
    cat = category_abbrev(category)
    seq = String.pad_leading(Integer.to_string(sequence), 3, "0")

    "#{inst}-#{dept}-#{cat}-#{seq}"
  end

  defp category_abbrev("handling"), do: "HAND"
  defp category_abbrev("digitization"), do: "DIGI"
  defp category_abbrev("preservation"), do: "PRES"
  defp category_abbrev("access"), do: "ACC"
  defp category_abbrev("storage"), do: "STOR"
  defp category_abbrev("security"), do: "SEC"
  defp category_abbrev(_), do: "GEN"
end
