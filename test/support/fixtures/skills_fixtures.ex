defmodule Resume.SkillsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Resume.Skills` context.
  """

  @doc """
  Generate a skill.
  """
  def skill_fixture(attrs \\ %{}) do
    category =
      (attrs[:category_id] && Resume.Categories.get_category!(attrs[:category_id])) ||
        Resume.CategoriesFixtures.category_fixture()

    {:ok, skill} =
      attrs
      |> Enum.into(%{
        description: "some description",
        link: "some link",
        name: "some name",
        category_id: category.id
      })
      |> Resume.Skills.create_skill()

    skill
  end
end
