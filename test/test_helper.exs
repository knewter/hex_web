ExUnit.start exclude: [:integration]

HexWeb.Config.url("http://hex.pm")
HexWeb.Config.password_work_factor(4)

Mix.Task.run "ecto.drop", ["HexWeb.Repo"]
Mix.Task.run "ecto.create", ["HexWeb.Repo"]
Mix.Task.run "ecto.migrate", ["HexWeb.Repo"]

File.rm_rf!("tmp")
File.mkdir_p!("tmp")

defmodule HexWebTest.Case do
  use ExUnit.CaseTemplate

  alias Ecto.Adapters.Postgres

  setup do
    Postgres.begin_test_transaction(HexWeb.Repo)
  end

  teardown do
    Postgres.rollback_test_transaction(HexWeb.Repo)
  end

  using do
    quote do
      import HexWebTest.Case
    end
  end

  @tmp Path.expand Path.join(__DIR__, "../tmp")

  def create_tar(meta, files) do
    contents_path = Path.join(@tmp, "#{meta[:app]}-#{meta[:version]}-contents.tar.gz")
    files = Enum.map(files, fn { name, bin } -> { String.to_char_list!(name), bin } end)
    :ok = :erl_tar.create(contents_path, files, [:compressed, :cooked])
    contents = File.read!(contents_path)

    meta_string = HexWeb.Util.safe_serialize_elixir(meta)
    blob = "1" <> meta_string <> contents
    checksum = :crypto.hash(:md5, blob) |> HexWeb.Util.hexify

    files = [
      { 'VERSION', "1"},
      { 'CHECKSUM', checksum },
      { 'metadata.exs', meta_string },
      { 'contents.tar.gz', contents } ]
    path = Path.join(@tmp, "#{meta[:app]}-#{meta[:version]}.tar")
    :ok = :erl_tar.create(path, files, [:cooked])

    File.read!(path)
  end
end
