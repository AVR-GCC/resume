defmodule Resume.Skills.Skill do
  use Ecto.Schema
  import Ecto.Changeset

  schema "skills" do
    field :name, :string
    field :link, :string
    field :description, :string
    field :category_id, :id

    many_to_many :projects, Resume.Projects.Project, join_through: "projects_skills"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(skill, attrs) do
    skill
    |> cast(attrs, [:name, :link, :description, :category_id])
    |> validate_required([:name, :link, :description, :category_id])
  end
end
