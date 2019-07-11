defmodule CacheCompare.Application do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([CacheCompare.Redix], strategy: :one_for_one)
  end

end
