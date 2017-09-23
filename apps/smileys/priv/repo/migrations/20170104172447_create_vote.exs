defmodule SmileysData.Repo.Migrations.CreateVote do
  use Ecto.Migration

  def change do
    create table(:votes) do
      add :username, :string
      add :postid, :integer
      add :vote, :string

      timestamps()
    end
    create unique_index(:votes, [:username, :postid])
    create index(:votes, [:postid])

  end
end
