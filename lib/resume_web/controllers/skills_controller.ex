defmodule ResumeWeb.SkillsController do
  use ResumeWeb, :controller

  def skills(conn, _params) do
    render(conn, :skills)
  end
end
