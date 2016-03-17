defmodule MrRoboto do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(MrRoboto.Agent, [])
    ]

    opts = [strategy: :one_for_one, name: MrRoboto]
    Supervisor.start_link(children, opts)
  end
end
