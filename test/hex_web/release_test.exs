defmodule HexWeb.ReleaseTest do
  use HexWebTest.Case

  alias HexWeb.User
  alias HexWeb.Package
  alias HexWeb.Release

  setup do
    { :ok, user } = User.create("eric", "eric@mail.com", "eric")
    { :ok, _ } = Package.create("ecto", user, %{})
    { :ok, _ } = Package.create("postgrex", user, %{})
    { :ok, _ } = Package.create("decimal", user, %{})
    :ok
  end

  test "create release and get" do
    package = Package.get("ecto")
    package_id = package.id
    assert { :ok, Release.Entity[package_id: ^package_id, version: "0.0.1"] } =
           Release.create(package, "0.0.1", [])
    assert Release.Entity[package_id: ^package_id, version: "0.0.1"] = Release.get(package, "0.0.1")

    assert { :ok, _ } = Release.create(package, "0.0.2", [])
    assert [ Release.Entity[version: "0.0.2"], Release.Entity[version: "0.0.1"] ] =
           Release.all(package)
  end

  test "create release with deps" do
    ecto = Package.get("ecto")
    postgrex = Package.get("postgrex")
    decimal = Package.get("decimal")

    assert { :ok, _ } = Release.create(decimal, "0.0.1", %{})
    assert { :ok, _ } = Release.create(decimal, "0.0.2", %{})
    assert { :ok, _ } = Release.create(postgrex, "0.0.1", %{"decimal" => "~> 0.0.1"})
    assert { :ok, _ } = Release.create(ecto, "0.0.1", %{"decimal" => "~> 0.0.2", "postgrex" => "== 0.0.1"})

    release = Release.get(ecto, "0.0.1")
    reqs = release.requirements.to_list
    assert Dict.size(reqs) == 2
    assert {"postgrex", "== 0.0.1" } in reqs
    assert {"decimal", "~> 0.0.2" } in reqs
  end

  test "validate release" do
    package = Package.get("ecto")

    assert { :ok, _ } =
           Release.create(package, "0.1.0", %{"decimal" => nil})

    assert { :error, %{version: "invalid version"} } =
           Release.create(package, "0.1", %{})

    assert { :error, %{version: "pre release version is not allowed"} } =
           Release.create(package, "0.1.0-dev", %{})

    assert { :error, %{deps: %{"decimal" => "invalid requirement: \"fail\"" }} } =
           Release.create(package, "0.1.1", %{"decimal" => "fail"})
  end

  test "release version is unique" do
    ecto = Package.get("ecto")
    postgrex = Package.get("postgrex")
    assert { :ok, Release.Entity[] } = Release.create(ecto, "0.0.1", %{})
    assert { :ok, Release.Entity[] } = Release.create(postgrex, "0.0.1", %{})
    assert { :error, _ } = Release.create(ecto, "0.0.1", %{})
  end

  test "update release" do
    decimal = Package.get("decimal")
    postgrex = Package.get("postgrex")

    assert { :ok, _ } = Release.create(decimal, "0.0.1", %{})
    assert { :ok, release } = Release.create(postgrex, "0.0.1", %{"decimal" => "~> 0.0.1"})

    Release.update(release, %{"decimal" => "~> 0.0.2"})

    release = Release.get(postgrex, "0.0.1")
    assert %{"decimal" => "~> 0.0.2"} = release.requirements.to_list
  end

  test "delete release" do
    decimal = Package.get("decimal")
    postgrex = Package.get("postgrex")

    assert { :ok, release } = Release.create(decimal, "0.0.1", %{})
    Release.delete(release)
    refute Release.get(postgrex, "0.0.1")
  end
end
