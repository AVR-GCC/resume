defmodule Resume.Repo.Migrations.CreateProjectsSkills do
  use Ecto.Migration

  def change do
    create table(:projects_skills) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :skill_id, references(:skills, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:projects_skills, [:project_id])
    create index(:projects_skills, [:skill_id])
    create unique_index(:projects_skills, [:project_id, :skill_id])
  end
end
