defmodule HexWeb.Stats.ReleaseDownload do
  use Ecto.Model
  import Ecto.Query, only: [from: 2]
  alias HexWeb.Stats.ReleaseDownload

  queryable "release_downloads", primary_key: false do
    belongs_to :release, HexWeb.Release
    field :downloads, :integer
  end

  def refresh do
    Ecto.Adapters.Postgres.query(
       HexWeb.Repo,
       "REFRESH MATERIALIZED VIEW release_downloads",
       [])
  end

  def release(release) do
    from(rd in ReleaseDownload,
         where: rd.release_id == ^release.id,
         select: rd.downloads)
    |> HexWeb.Repo.all
    |> List.first
  end
end
