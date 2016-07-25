defmodule Delayed.Consumer do
  @moduledoc false

  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, :state)
  end

  ## Callbacks

  def init(state) do
    {:consumer, state, subscribe_to: [Delayed.Producer]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      %{id: id, payload: binary} = event
      {mod, fun, args} = :erlang.binary_to_term(binary)
      task = start_task(mod, fun, args)

      task
      |> Task.yield(1000)
      |> yield_to_status(task)
      |> update(id)
    end
    {:noreply, [], state}
  end

  defp start_task(mod, fun, args) do
    Task.Supervisor.async_nolink(Delayed.TaskSupervisor, mod, fun, args)
  end

  defp yield_to_status({:ok, _}, _) do
    "success"
  end
  defp yield_to_status({:exit, _}, _) do
    "error"
  end
  defp yield_to_status(nil, task) do
    Task.shutdown(task)
    "timedout"
  end

  defp update(status, id) do
    Delayed.Job.update_status(id, status)
  end
end
