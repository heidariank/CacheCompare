defmodule ConnPool do
  alias CacheCompare.Redix, as: CRedix

  CacheCompare.Application.start({}, {})
  :ets.new(:tab, [:named_table, :public])

  Benchee.run(%{
    "ets_insert" => fn -> :ets.insert(:tab, {:k, :v}) end,
    "redis_insert" => fn -> CRedix.command(["SET", :k, :v]) end
  })

  Benchee.run(%{
    "ets_read" => fn -> :ets.lookup(:tab, :k) end,
    "redis_read" => fn -> CRedix.command(["GET", :k]) end
  })

  # keys = Enum.map(0..1000, fn _n -> Enum.random(0..1000) |> Integer.to_string() end)
  # write_pipe = Enum.map(keys, fn k -> ["SET", k, k] end)

  # Benchee.run(%{
  #   "ets_list_insert" => fn -> Enum.each(keys, fn k -> :ets.insert(:tab, {k, k}) end) end,
  #   "redis_conn_pool_pipeline" => fn -> CRedix.pipeline(write_pipe) end,
  #   "redis_conn_pool_plain_old_command" => fn -> Enum.each(keys, fn k -> CRedix.command(["SET", k, k]) end) end
  # })

  # read_pipe = Enum.map(keys, fn k -> ["GET", k] end)

  # Benchee.run(%{
  #   "ets_list_read" => fn -> Enum.each(keys, fn k -> :ets.lookup(:tab, k) end) end,
  #   "redis_conn_pool_read" => fn -> CRedix.pipeline(read_pipe) end,
  #   "redis_conn_pool_plain_old_command" => fn -> Enum.each(keys, fn k -> CRedix.command(["GET", k]) end) end
  # })
end
