defmodule CacheCompare.Redix do
  @moduledoc """
    Module for interacting with a Redix cache, uses a pool of connections for better access
  """
  @pool_size 5

  # alias Redix
  def child_spec(_args) do
    # Specs for the Redix connections.
    children =
      for i <- 0..(@pool_size - 1) do
        Supervisor.child_spec({Redix, name: :"redix_#{i}"}, id: {Redix, i})
      end

    # Spec for the supervisor that will supervise the Redix connections.
    %{
      id: RedixSupervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [children, [strategy: :one_for_one]]}
    }
  end

  @spec command([binary]) :: {:ok, Protocol.redis_value()} | {:error, atom | Error.t()}
  def command(command) do
    Redix.command(:"redix_#{random_index()}", command)
  end

  @spec command([binary]) :: {:ok, Protocol.redis_value()} | {:error, atom | Error.t()}
  def pipeline(pipeline) do
    Redix.pipeline(:"redix_#{random_index()}", pipeline)
  end

  @spec random_index() :: integer
  defp random_index do
    rem(System.unique_integer([:positive]), @pool_size)
  end
end
