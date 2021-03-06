defmodule HexWeb.PackageTest do
  use HexWebTest.Case

  alias HexWeb.User
  alias HexWeb.Package

  setup do
    { :ok, _ } = User.create("eric", "eric@mail.com", "eric")
    :ok
  end

  test "create package and get" do
    user = User.get("eric")
    user_id = user.id
    assert { :ok, Package.Entity[] } = Package.create("ecto", user, %{})
    assert Package.Entity[owner_id: ^user_id] = Package.get("ecto")
    assert nil?(Package.get("postgrex"))
  end

  test "update package" do
    user = User.get("eric")
    assert { :ok, package } = Package.create("ecto", user, %{})

    Package.update(package, %{"contributors" => ["eric", "josé"]})
    package = Package.get("ecto")
    assert Dict.size(package.meta["contributors"]) == 2
  end

  test "validate valid meta" do
    meta = %{
      "contributors" => ["eric", "josé"],
      "licenses"     => ["apache", "BSD"],
      "links"        => %{"github" => "www", "docs" => "www"},
      "description"  => "so good" }

    user = User.get("eric")
    assert { :ok, Package.Entity[meta: ^meta] } = Package.create("ecto", user, meta)
    assert Package.Entity[meta: ^meta] = Package.get("ecto")
  end

  test "ignore unknown meta fields" do
    meta = %{
      "contributors" => ["eric"],
      "foo"          => "bar" }

    user = User.get("eric")
    assert { :ok, Package.Entity[] } = Package.create("ecto", user, meta)
    assert Package.Entity[meta: meta2] = Package.get("ecto")

    assert Dict.size(meta2) == 1
    assert meta["contributors"] == meta2["contributors"]
  end

  test "validate invalid meta" do
    meta = %{
      "contributors" => "eric",
      "licenses"     => 123,
      "links"        => ["url"],
      "description"  => ["so bad"] }

    user = User.get("eric")
    assert { :error, errors } = Package.create("ecto", user, meta)
    assert Dict.size(errors) == 1
    assert Dict.size(errors[:meta]) == 4
  end

  test "packages are unique" do
    user = User.get("eric")
    assert { :ok, Package.Entity[] } = Package.create("ecto", user, %{})
    assert { :error, _ } = Package.create("ecto", user, %{})
  end
end
