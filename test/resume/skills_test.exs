defmodule Resume.SkillsTest do
  use Resume.DataCase

  alias Resume.Skills

  describe "skills" do
    alias Resume.Skills.Skill

    import Resume.SkillsFixtures

    @invalid_attrs %{name: nil, link: nil, description: nil}

    test "list_skills/0 returns all skills" do
      skill = skill_fixture()
      assert Skills.list_skills() == [skill]
    end

    test "get_skill!/1 returns the skill with given id" do
      skill = skill_fixture()
      assert Skills.get_skill!(skill.id) == skill
    end

    test "create_skill/1 with valid data creates a skill" do
      category = Resume.CategoriesFixtures.category_fixture()

      valid_attrs = %{
        name: "some name",
        link: "some link",
        description: "some description",
        category_id: category.id
      }

      assert {:ok, %Skill{} = skill} = Skills.create_skill(valid_attrs)
      assert skill.name == "some name"
      assert skill.link == "some link"
      assert skill.description == "some description"
      assert skill.category_id == category.id
    end

    test "create_skill/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Skills.create_skill(@invalid_attrs)
    end

    test "update_skill/2 with valid data updates the skill" do
      skill = skill_fixture()

      update_attrs = %{
        name: "some updated name",
        link: "some updated link",
        description: "some updated description"
      }

      assert {:ok, %Skill{} = skill} = Skills.update_skill(skill, update_attrs)
      assert skill.name == "some updated name"
      assert skill.link == "some updated link"
      assert skill.description == "some updated description"
    end

    test "update_skill/2 with invalid data returns error changeset" do
      skill = skill_fixture()
      assert {:error, %Ecto.Changeset{}} = Skills.update_skill(skill, @invalid_attrs)
      assert skill == Skills.get_skill!(skill.id)
    end

    test "delete_skill/1 deletes the skill" do
      skill = skill_fixture()
      assert {:ok, %Skill{}} = Skills.delete_skill(skill)
      assert_raise Ecto.NoResultsError, fn -> Skills.get_skill!(skill.id) end
    end

    test "change_skill/1 returns a skill changeset" do
      skill = skill_fixture()
      assert %Ecto.Changeset{} = Skills.change_skill(skill)
    end
  end
end
