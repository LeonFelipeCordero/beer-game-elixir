defmodule BeerGame.LiveSessionStoreTest do
  use ExUnit.Case, async: false

  alias BeerGame.LiveSessionStore

  setup do
    ids = for _ <- 1..2, do: "store-test-#{System.unique_integer([:positive])}"

    on_exit(fn ->
      :sys.replace_state(LiveSessionStore, &Map.drop(&1, ids))
    end)

    {:ok, ids: ids}
  end

  test "concurrent writes preserve every key and stay isolated by browser", %{ids: [id, other]} do
    writes = for key <- 1..30, do: Task.async(fn -> LiveSessionStore.put(id, key, key * 2) end)
    other_write = Task.async(fn -> LiveSessionStore.put(other, "player", "other-player") end)
    assert Enum.all?(Task.await_many(writes), &(&1 == :ok))
    assert Task.await(other_write) == :ok
    assert LiveSessionStore.get(id) == Map.new(1..30, &{&1, &1 * 2})
    assert LiveSessionStore.get(other) == %{"player" => "other-player"}
  end

  test "expired sessions are discarded before reads and new writes", %{ids: [id, other]} do
    expiry = System.monotonic_time(:second) - 1

    :sys.replace_state(LiveSessionStore, fn state ->
      state
      |> Map.put(id, {%{"player" => "stale"}, expiry})
      |> Map.put(other, {%{"board" => "stale"}, expiry})
    end)

    assert LiveSessionStore.get(id) == %{}
    assert :ok = LiveSessionStore.put(other, "order_time", true)
    assert LiveSessionStore.get(other) == %{"order_time" => true}
  end

  test "cleanup removes only expired sessions", %{ids: [id, other]} do
    assert :ok = LiveSessionStore.put(other, "player", "active")

    :sys.replace_state(LiveSessionStore, fn state ->
      Map.put(state, id, {%{"player" => "stale"}, System.monotonic_time(:second) - 1})
    end)

    send(Process.whereis(LiveSessionStore), :cleanup)
    state = :sys.get_state(LiveSessionStore)
    refute Map.has_key?(state, id)
    assert Map.has_key?(state, other)
    assert LiveSessionStore.get(other) == %{"player" => "active"}
  end
end
