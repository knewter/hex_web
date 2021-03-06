defmodule HexWeb.Stats.PackageDownload do
  use Ecto.Model
  import Ecto.Query, only: [from: 2]
  alias HexWeb.Stats.PackageDownload

  queryable "package_downloads", primary_key: false do
    belongs_to :package, HexWeb.Package
    field :view, :string
    field :downloads, :integer
  end

  def refresh do
    Ecto.Adapters.Postgres.query(
       HexWeb.Repo,
       "REFRESH MATERIALIZED VIEW package_downloads",
       [])
  end

  def top(view, count) do
    view = "#{view}"
    from(pd in PackageDownload,
         join: p in pd.package,
         where: pd.package_id != nil and pd.view == ^view,
         order_by: [desc: pd.downloads],
         limit: count,
         select: { p.name, pd.downloads })
    |> HexWeb.Repo.all
  end

  def total do
    from(pd in PackageDownload, where: pd.package_id == nil)
    |> HexWeb.Repo.all
    |> Enum.map(&{ :"#{&1.view}", &1.downloads || 0 })
  end

  def package(package) do
    from(pd in PackageDownload, where: pd.package_id == ^package.id)
    |> HexWeb.Repo.all
    |> Enum.map(&{ :"#{&1.view}", &1.downloads || 0 })
  end
end
