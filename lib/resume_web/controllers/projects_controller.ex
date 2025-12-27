defmodule ResumeWeb.ProjectsController do
  use ResumeWeb, :controller
  alias Resume.Projects

  def projects(conn, _params) do
    projects = Projects.list_projects()

    render(conn, :projects, projects: projects)
  end
end
