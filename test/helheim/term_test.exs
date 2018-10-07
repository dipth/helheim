defmodule Helheim.TermTest do
  use Helheim.DataCase
  alias Helheim.Term

  @valid_attrs %{body: "Foo Bar"}

  describe "changeset/2" do
    test "it is valid with valid attrs" do
      changeset = Term.changeset(%Term{}, @valid_attrs)
      assert changeset.valid?
    end

    test "it requires a body" do
      changeset = Term.changeset(%Term{}, Map.delete(@valid_attrs, :body))
      refute changeset.valid?
    end

    test "it trims the body" do
      changeset = Term.changeset(%Term{}, Map.merge(@valid_attrs, %{body: "   Hello   "}))
      assert changeset.changes.body == "Hello"
    end
  end

  describe "newest/1" do
    test "it orders newer terms before older ones" do
      term1 = insert(:term)
      term2 = insert(:term)
      [first, last] = Term |> Term.newest |> Repo.all
      assert first.id == term2.id
      assert last.id  == term1.id
    end
  end

  describe "published/1" do
    test "it filters out terms that aren't published" do
      _term1 = insert(:term, published: false)
      term2  = insert(:term, published: true)
      term   = Term |> Term.published |> Repo.one
      assert term.id == term2.id
    end
  end
end
