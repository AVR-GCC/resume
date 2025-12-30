defmodule Resume.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :title, :string
    field :description, :string
    field :repo, :string
    field :live, :string

    many_to_many :skills, Resume.Skills.Skill, join_through: "projects_skills"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:title, :description, :repo, :live])
    |> validate_required([:title, :description, :repo, :live])
  end
end
