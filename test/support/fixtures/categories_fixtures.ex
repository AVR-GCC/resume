defmodule Resume.CategoriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Resume.Categories` context.
  """

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        icon: "some icon",
        name: "some name"
      })
      |> Resume.Categories.create_category()

    category
  end
end
