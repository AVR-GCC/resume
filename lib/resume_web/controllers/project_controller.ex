defmodule ResumeWeb.ProjectController do
  use ResumeWeb, :controller

  import Ecto.Query

  alias Resume.Projects
  alias Resume.Projects.Project
  alias Resume.Skills

  def index(conn, _params) do
    projects = Projects.list_projects()
    render(conn, :index, projects: projects)
  end

  def new(conn, _params) do
    changeset = Projects.change_project(%Project{})
    skills = Skills.list_skills()
    render(conn, :new, changeset: changeset, skills: skills)
  end

  def create(conn, %{"project" => project_params}) do
    case Projects.create_project(project_params) do
      {:ok, project} ->
        project_skills =
          project_params
          |> Map.get("skill_ids", [])
          |> Enum.map(fn skill ->
            {skill_id, _} = Integer.parse(skill)

            %{
              project_id: project.id,
              skill_id: skill_id,
              inserted_at: NaiveDateTime.utc_now(),
              updated_at: NaiveDateTime.utc_now()
            }
          end)

        Resume.Repo.insert_all("projects_skills", project_skills)

        conn
        |> put_flash(:info, "Project created successfully.")
        |> redirect(to: ~p"/admin/projects/#{project}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    project = Projects.get_project!(id)
    render(conn, :show, project: project)
  end

  def edit(conn, %{"id" => id}) do
    project = Projects.get_project!(id)
    changeset = Projects.change_project(project)
    skills = Skills.list_skills()
    render(conn, :edit, project: project, changeset: changeset, skills: skills)
  end

  def update(conn, %{"id" => id, "project" => project_params}) do
    project = Projects.get_project!(id)

    case Projects.update_project(project, project_params) do
      {:ok, project} ->
        # Remove existing project-skill associations
        Resume.Repo.delete_all(
          from ps in "projects_skills",
            where: field(ps, :project_id) == ^project.id
        )

        project_skills =
          project_params
          |> Map.get("skill_ids", [])
          |> Enum.map(fn skill ->
            {skill_id, _} = Integer.parse(skill)

            %{
              project_id: project.id,
              skill_id: skill_id,
              inserted_at: NaiveDateTime.utc_now(),
              updated_at: NaiveDateTime.utc_now()
            }
          end)

        Resume.Repo.insert_all("projects_skills", project_skills)

        conn
        |> put_flash(:info, "Project updated successfully.")
        |> redirect(to: ~p"/admin/projects/#{project}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, project: project, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    project = Projects.get_project!(id)
    {:ok, _project} = Projects.delete_project(project)

    conn
    |> put_flash(:info, "Project deleted successfully.")
    |> redirect(to: ~p"/admin/projects")
  end
end
