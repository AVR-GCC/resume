defmodule ResumeWeb.ProjectsController do
  use ResumeWeb, :controller

  def projects(conn, _params) do
    render(conn, :projects)
  end
end
