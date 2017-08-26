defmodule Smileys.Repo.Migrations.CreateRoom do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string
      add :creatorid, :integer
      add :title, :string
      add :description, :string
      add :type, :string
      add :reputation, :integer
      add :age, :integer

      timestamps()
    end
    create unique_index(:rooms, [:name])
    create index(:rooms, [:type])
    create index(:rooms, [:creatorid])
    create index(:rooms, [:age])

  end
end
