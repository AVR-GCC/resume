defmodule ResumeWeb.MessageController do
  use ResumeWeb, :controller

  alias Resume.Messages
  alias Resume.Messages.Message

  def index(conn, _params) do
    messages = Messages.list_messages()
    render(conn, :index, messages: messages)
  end

  def new(conn, _params) do
    changeset = Messages.change_message(%Message{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"message" => message_params}) do
    case Messages.create_message(message_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Message sent, will get back to you shortly!")
        |> redirect(to: ~p"/contact")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    message = Messages.get_message!(id)
    render(conn, :show, message: message)
  end

  def delete(conn, %{"id" => id}) do
    message = Messages.get_message!(id)
    {:ok, _message} = Messages.delete_message(message)

    conn
    |> put_flash(:info, "Message deleted successfully.")
    |> redirect(to: ~p"/admin/messages")
  end
end
