defmodule Resume.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Resume.Projects` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        description: "some description",
        live: "some live",
        repo: "some repo",
        title: "some title"
      })
      |> Resume.Projects.create_project()

    project
  end
end
