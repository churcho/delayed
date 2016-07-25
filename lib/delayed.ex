defmodule Delayed do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @doc false
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(Delayed.Repo, []),
      worker(Delayed.Producer, []),
      supervisor(Task.Supervisor, [[name: Delayed.TaskSupervisor]])
    ]

    consumers =
      for id <- 1..System.schedulers_online * 2 do
        worker(Delayed.Consumer, [], id: id)
      end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Delayed.Supervisor]
    Supervisor.start_link(children ++ consumers, opts)
  end

  defdelegate enqueue(module, function, args), to: Delayed.Producer
end
