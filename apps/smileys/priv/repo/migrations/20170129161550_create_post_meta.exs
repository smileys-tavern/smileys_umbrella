defmodule Smileys.Repo.Migrations.CreatePostMeta do
  use Ecto.Migration

  def change do
    create table(:postmetas) do
      add :userid, :integer
      add :postid, :integer
      add :link, :string
      add :image, :string
      add :thumb, :string
      add :tags, :string

      timestamps()
    end
    create unique_index(:postmetas, [:postid])
    create index(:postmetas, [:userid])

  end
end
