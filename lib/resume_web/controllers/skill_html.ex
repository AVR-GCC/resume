defmodule ResumeWeb.SkillHTML do
  use ResumeWeb, :html

  embed_templates "skill_html/*"

  @doc """
  Renders a skill form.

  The form is defined in the template at
  skill_html/skill_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def skill_form(assigns)
end
