defmodule Resume.MessagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Resume.Messages` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        content: "some content",
        email: "some email",
        name: "some name"
      })
      |> Resume.Messages.create_message()

    message
  end
end
