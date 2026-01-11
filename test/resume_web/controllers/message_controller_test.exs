defmodule ResumeWeb.MessageControllerTest do
  use ResumeWeb.ConnCase

  import Resume.MessagesFixtures

  @create_attrs %{name: "some name", email: "some email", content: "some content"}

  describe "index" do
    test "lists all messages", %{conn: conn} do
      conn = get(conn, ~p"/admin/messages")
      assert html_response(conn, 200) =~ "Messages"
    end
  end

  describe "create message" do
    test "redirects to contact when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/messages", message: @create_attrs)
      assert redirected_to(conn) == ~p"/contact"
    end
  end

  describe "show message" do
    setup [:create_message]

    test "shows chosen message", %{conn: conn, message: message} do
      conn = get(conn, ~p"/admin/messages/#{message}")
      assert html_response(conn, 200) =~ "Message #{message.id}"
    end
  end

  describe "delete message" do
    setup [:create_message]

    test "deletes chosen message", %{conn: conn, message: message} do
      conn = delete(conn, ~p"/admin/messages/#{message}")
      assert redirected_to(conn) == ~p"/admin/messages"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/messages/#{message}")
      end
    end
  end

  defp create_message(_) do
    message = message_fixture()

    %{message: message}
  end
end
