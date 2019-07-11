defmodule CacheCompare do
  @moduledoc """
  Documentation for CacheCompare.
  """

  alias CacheCompare.Redix, as: CRedix

  @table :tab

  def main() do
    keys = Enum.map(0..10000, fn _n -> rand_string(1000) end)
    {:ok, conn} = Redix.start_link(Application.get_env(:redix, :url))
    measure(&redix_write/2, [conn, keys])

    :ets.new(@table, [:named_table])

  end

  def ets_vs_redis() do
    keys = Enum.map(0..1000, fn _n -> rand_string(1000) end)
    {:ok, conn} = Redix.start_link(Application.get_env(:redix, :url))

    {redix_time,_} = measure(&redix_write/2, [conn, keys])

    create_table()
    {ets_time, _} = measure(&ets_write/2, [@table, keys])
    IO.puts("WRITE - ets is #{redix_time / ets_time} times faster that redis")


    {redix_time,_} = measure(&redix_read/2, [conn, keys])
    {ets_time, _} = measure(&ets_read/2, [@table, keys])
    IO.puts("READ - ets is #{redix_time / ets_time} times faster that redis")
  end

  def ets_vs_pipeline(table_name) do
    keys = Enum.map(0..10000, fn _n -> rand_string(1000) end)
    {:ok, conn} = Redix.start_link(Application.get_env(:redix, :url))
    pipe_write = Enum.map(keys, fn k -> ["SET", k, k] end)

    {redix_time,_} = measure(&Redix.pipeline/2, [conn, pipe_write])

    # create_table()
    {ets_time, _} = measure(&ets_write/2, [table_name, keys])
    IO.puts("WRITE - ets is #{redix_time / ets_time} times faster that redis")

    pipe_read = Enum.map(keys, fn k -> ["GET", k] end)
    {redix_time,_} = measure(&Redix.pipeline/2, [conn, pipe_read])
    {ets_time, _} = measure(&ets_read/2, [table_name, keys])
    IO.puts("READ - ets is #{redix_time / ets_time} times faster that redis")
  end

  def ets_vs_conn_pool() do
    keys = Enum.map(0..10000, fn _n -> rand_string(1000) end)
    pipe_write = Enum.map(keys, fn k -> ["SET", k, k] end)

    {redix_time,_} = measure(&CRedix.pipeline/1, [pipe_write]) |> IO.inspect(label: "Redix conn pool result")

    create_table()
    {ets_time, _} = measure(&ets_write/2, [@table, keys]) |> IO.inspect(label: "ets result")
    IO.puts("ets is #{redix_time / ets_time} times faster that redis")
  end

  def conncurrent_ets(table) do
    # tasks = Enum.map(0..5, Task.async(fn -> ets_write(table, rand_keys(2000) end)))
    keys = rand_keys(10_000)
    tasks = Enum.map(0..5, fn _ -> Task.async(fn -> measure(&ets_write/2, [table, keys]) end) end)
    ets_time =
    tasks
    |> Enum.map(fn t -> Task.await(t) end)
    |> Enum.map(fn {time, :ok} -> time end)
    |> Enum.max()

    {:ok, conn} = Redix.start_link(Application.get_env(:redix, :url))
    pipe_write = Enum.map(keys, fn k -> ["SET", k, k] end)
    {redix_time,_} = measure(&Redix.pipeline/2, [conn, pipe_write])

    IO.puts("WRITE - ets is #{redix_time / ets_time} times faster that redis")
  end



  def measure(function, args) do
    function
    |> :timer.tc(args)
  end

  ###
  def redix_write(conn, keys) do
    Enum.each(keys, fn k -> Redix.command(conn, ["SET", k, k]) end)
    # Enum.each(0..iterations, fn -> Redix.command(conn, ["SET", gen_key(), gen_val()]))
  end

  def redix_read(conn, keys) do
    Enum.each(keys, fn k -> Redix.command(conn, ["GET", k]) end)
    # Enum.each(0..iterations, fn -> Redix.command(conn, ["GET", gen_key()]))
  end
  ##

  def pipe_write(conn, keys) do
    pipe = Enum.map(keys, fn k -> ["SET", k, k] end)
    measure(&Redix.pipeline/2, [conn, pipe])
  end

  def ets_write(table, keys) do
    Enum.each(keys, fn k -> :ets.insert(table, {k, k}) end)
  end

  def ets_read(table, keys) do
    Enum.each(keys, fn k -> :ets.lookup(table, k) end)
  end

  def rand_string(count) do
    Enum.random(0..count) |> Integer.to_string()
  end

  defp create_table() do
    if(:ets.info(@table) == :undefined,
    do:
      :ets.new(@table, [
        :named_table
      ])
  )
  end

  defp rand_keys(size) do
    Enum.map(0..size, fn _n -> rand_string(1000) end)
  end
end
