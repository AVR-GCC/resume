defmodule ResumeWeb.SkillController do
  use ResumeWeb, :controller

  alias Resume.Skills
  alias Resume.Skills.Skill
  alias Resume.Categories

  def index(conn, _params) do
    skills = Skills.list_skills()
    categories = Categories.list_categories()
    categories_map = Map.new(categories, fn c -> {c.id, c} end)
    render(conn, :index, skills: skills, categories: categories_map)
  end

  def new(conn, _params) do
    changeset = Skills.change_skill(%Skill{})
    categories = Categories.list_categories()
    category_options = category_options(categories)
    render(conn, :new, changeset: changeset, categories: category_options)
  end

  def create(conn, %{"skill" => skill_params}) do
    case Skills.create_skill(skill_params) do
      {:ok, skill} ->
        conn
        |> put_flash(:info, "Skill created successfully.")
        |> redirect(to: ~p"/admin/skills/#{skill}")

      {:error, %Ecto.Changeset{} = changeset} ->
        categories = Categories.list_categories()
        render(conn, :new, changeset: changeset, categories: category_options(categories))
    end
  end

  def show(conn, %{"id" => id}) do
    skill = Skills.get_skill!(id)
    render(conn, :show, skill: skill)
  end

  def edit(conn, %{"id" => id}) do
    skill = Skills.get_skill!(id)
    changeset = Skills.change_skill(skill)
    categories = Categories.list_categories()

    render(conn, :edit,
      skill: skill,
      changeset: changeset,
      categories: category_options(categories)
    )
  end

  def update(conn, %{"id" => id, "skill" => skill_params}) do
    skill = Skills.get_skill!(id)

    case Skills.update_skill(skill, skill_params) do
      {:ok, skill} ->
        conn
        |> put_flash(:info, "Skill updated successfully.")
        |> redirect(to: ~p"/admin/skills/#{skill}")

      {:error, %Ecto.Changeset{} = changeset} ->
        categories = Categories.list_categories()

        render(conn, :edit,
          skill: skill,
          changeset: changeset,
          categories: category_options(categories)
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    skill = Skills.get_skill!(id)
    {:ok, _skill} = Skills.delete_skill(skill)

    conn
    |> put_flash(:info, "Skill deleted successfully.")
    |> redirect(to: ~p"/admin/skills")
  end

  def skills(conn, _params) do
    categories = Categories.list_categories()

    skills =
      Skills.list_skills()
      |> Enum.reduce(%{}, fn s, acc ->
        Map.update(acc, s.category_id, [s], &[s | &1])
      end)

    render(conn, :skills, categories: categories, skills: skills)
  end

  defp category_options(categories) do
    Enum.map(categories, fn cat -> {cat.name, cat.id} end)
  end
end
