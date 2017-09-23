defmodule SmileysData.Repo.Migrations.CreateUserSubscription do
  use Ecto.Migration

  def change do
    create table(:usersubscriptions) do
      add :userid, :integer
      add :roomname, :string
      add :type, :string

      timestamps()
    end
    create unique_index(:usersubscriptions, [:userid, :roomname])
    create index(:usersubscriptions, [:userid])

  end
end
