defmodule SmileysData.Repo.Migrations.CreatePost do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :posterid, :integer
      add :title, :string, size: 350
      add :body, :string, size: 3800
      add :superparentid, :integer
      add :parentid, :integer
      add :parenttype, :string
      add :age, :integer
      add :hash, :string
      add :votepublic, :integer
      add :voteprivate, :integer
      add :votealltime, :integer
      add :ophash, :string

      timestamps()
    end
    create index(:posts, [:posterid])
    create index(:posts, [:votepublic])
    create index(:posts, [:voteprivate])
    create index(:posts, [:votealltime])
    create index(:posts, [:hash])
    create index(:posts, [:superparentid])
    create index(:posts, [:parentid])
    create index(:posts, [:parenttype])
    create index(:posts, [:parenttype, :parentid])

  end
end
