defmodule EtsVsRedis do

  :ets.new(:tab, [:named_table, :public])

  {:ok, conn} = Redix.start_link(Application.get_env(:redix, :url))

  Benchee.run(%{
    "ets_insert" => fn -> :ets.insert(:tab, {:k, :v}) end,
    "redis_insert" => fn -> Redix.command(conn, ["SET", :k, :v]) end
  })

  Benchee.run(%{
    "ets_read" => fn -> :ets.lookup(:tab, :k) end,
    "redis_read" => fn -> Redix.command(conn, ["GET", :k]) end
  })
end
