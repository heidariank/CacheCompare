defmodule ConcurrentEts do

  :ets.new(:tab, [:named_table, :public, read_concurrency: true, write_concurrency: true])

  {:ok, conn} = Redix.start_link(Application.get_env(:redix, :url))

  keys = Enum.map(0..1000, fn _n -> Enum.random(0..1000) |> Integer.to_string() end)
  pipe = Enum.map(keys, fn k -> ["SET", k, k] end)

  Benchee.run(%{
    "ets_list_insert" => fn -> Enum.each(keys, fn k -> :ets.insert(:tab, {k, k}) end) end,
    "redis_pipe_write" => fn -> Redix.pipeline(conn, pipe) end
  },
  parallel: 4)

  pipe = Enum.map(keys, fn k -> ["GET", k] end)

  Benchee.run(%{
    "ets_list_read" => fn -> Enum.each(keys, fn k -> :ets.lookup(:tab, k) end) end,
    "redis_pipe_read" => fn -> Redix.pipeline(conn, pipe) end
  },
  parallel: 4)
end
