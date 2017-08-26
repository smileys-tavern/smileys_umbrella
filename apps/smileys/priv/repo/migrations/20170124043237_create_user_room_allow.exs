defmodule Smileys.Repo.Migrations.CreateUserRoomAllow do
  use Ecto.Migration

  def change do
    create table(:userroomallows) do
      add :username, :string
      add :roomname, :string

      timestamps()
    end
    create unique_index(:userroomallows, [:username, :roomname])
    create index(:userroomallows, [:username])

  end
end
