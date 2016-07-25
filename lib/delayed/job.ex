defmodule Delayed.Job do
  @moduledoc false

  import Ecto.Query

  def update_status(id, status) do
    Delayed.Repo.update_all by_ids([id]), set: [status: status]
  end

  def enqueue(status, payload) do
    Delayed.Repo.insert_all "jobs", [
      %{status: status, payload: payload}
    ]
  end

  def take(limit) do
    {:ok, {count, events}} =
      Delayed.Repo.transaction fn ->
        ids = Delayed.Repo.all waiting(limit)
        Delayed.Repo.update_all by_ids(ids), [set: [status: "running"]], [returning: [:id, :payload]]
      end
    {count, events}
  end

  defp waiting(limit) do
    from j in "jobs", where: j.status == "waiting", limit: ^limit,
                      select: j.id, lock: "FOR UPDATE SKIP LOCKED"
  end

  defp by_ids(ids) do
    from j in "jobs", where: j.id in ^ids
  end
end
