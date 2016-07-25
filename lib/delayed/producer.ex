defmodule Delayed.Producer do
  @moduledoc false
  use GenStage

  @name __MODULE__
  import Ecto.Query

  def start_link() do
    GenStage.start_link(__MODULE__, 0, name: @name)
  end

  def enqueue(module, function, args) do
    Delayed.Job.enqueue("waiting", :erlang.term_to_binary({module, function, args}))
    Process.send(@name, :enqueued)
    :ok
  end

  ## Callbacks

  def init(state) do
    {:producer, state}
  end

  def handle_cast(:enqueued, state) do
    serve_jobs(state)
  end

  def handle_demand(demand, state) do
    serve_jobs(demand + state)
  end

  defp serve_jobs(0) do
    {:noreply, [], 0}
  end

  defp serve_jobs(limit) when limit > 0 do
    # cancel previous timer
    {count, events} = Delayed.Job.take(limit)
    timer = Process.send_after(@name, :enqueued, 60_000)
    {:noreply, events, limit - count}
  end
end
