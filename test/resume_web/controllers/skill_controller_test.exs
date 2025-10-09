defmodule ResumeWeb.SkillControllerTest do
  use ResumeWeb.ConnCase

  import Resume.SkillsFixtures

  @create_attrs %{name: "some name", link: "some link", description: "some description"}
  @update_attrs %{
    name: "some updated name",
    link: "some updated link",
    description: "some updated description"
  }
  @invalid_attrs %{name: nil, link: nil, description: nil}

  describe "index" do
    test "lists all skills", %{conn: conn} do
      conn = get(conn, ~p"/skills")
      assert html_response(conn, 200) =~ "Listing Skills"
    end
  end

  describe "new skill" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/skills/new")
      assert html_response(conn, 200) =~ "New Skill"
    end
  end

  describe "create skill" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/skills", skill: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/skills/#{id}"

      conn = get(conn, ~p"/skills/#{id}")
      assert html_response(conn, 200) =~ "Skill #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/skills", skill: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Skill"
    end
  end

  describe "edit skill" do
    setup [:create_skill]

    test "renders form for editing chosen skill", %{conn: conn, skill: skill} do
      conn = get(conn, ~p"/skills/#{skill}/edit")
      assert html_response(conn, 200) =~ "Edit Skill"
    end
  end

  describe "update skill" do
    setup [:create_skill]

    test "redirects when data is valid", %{conn: conn, skill: skill} do
      conn = put(conn, ~p"/skills/#{skill}", skill: @update_attrs)
      assert redirected_to(conn) == ~p"/skills/#{skill}"

      conn = get(conn, ~p"/skills/#{skill}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, skill: skill} do
      conn = put(conn, ~p"/skills/#{skill}", skill: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Skill"
    end
  end

  describe "delete skill" do
    setup [:create_skill]

    test "deletes chosen skill", %{conn: conn, skill: skill} do
      conn = delete(conn, ~p"/skills/#{skill}")
      assert redirected_to(conn) == ~p"/skills"

      assert_error_sent 404, fn ->
        get(conn, ~p"/skills/#{skill}")
      end
    end
  end

  defp create_skill(_) do
    skill = skill_fixture()

    %{skill: skill}
  end
end
