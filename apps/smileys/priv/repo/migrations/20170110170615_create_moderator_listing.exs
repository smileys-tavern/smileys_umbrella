defmodule Smileys.Repo.Migrations.CreateModeratorListing do
  use Ecto.Migration

  def change do
    create table(:moderatorlistings) do
      add :userid, :integer
      add :roomid, :integer
      add :type, :string

      timestamps()
    end
    create unique_index(:moderatorlistings, [:userid, :roomid])
    create index(:moderatorlistings, [:userid])

  end
end
