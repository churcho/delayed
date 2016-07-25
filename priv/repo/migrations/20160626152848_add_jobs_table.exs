defmodule Delayed.Repo.Migrations.AddJobsTable do
  use Ecto.Migration

  def change do
    create table(:jobs) do
      add :payload, :binary
      add :status, :string
    end
  end
end
