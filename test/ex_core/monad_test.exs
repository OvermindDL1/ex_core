defmodule ExCore.MonadTest do
  use ExUnit.Case
  alias ExCore.Monad
  # doctest Monad

  test "List" do
    assert [42] == Monad.wrap(42, [])
    assert [1, 1, 2, 2, 3, 3] = Monad.flat_map([1,2,3], &[&1, &1])
    assert [1, 2, 3, 6] =
      [1, 2, 3, 4]
      |> Monad.flat_map(fn x when rem(x, 2) === 1 -> [x]; _ -> [] end)
      |> Monad.flat_map(&[&1, &1 * 2])
  end

  test "Map" do
    assert %{a: 42} = Monad.wrap({:a, 42}, %{})
    assert %{:a => 1, :b => 2, 1 => :a, 2 => :b} =
      Monad.flat_map(%{a: 1, b: 2}, fn {key, value} -> %{key => value, value => key} end)
    assert %{:b => 4, 4 => :b} =
      %{a: 1, b: 2}
      |> Monad.flat_map(fn {_key, 1} -> %{}; {key, value} -> %{key => value * 2} end)
      |> Monad.flat_map(fn {key, value} -> %{key => value, value => key} end)

    # But not structs
    assert_raise(ProtocolEx.UnimplementedProtocolEx, fn -> Monad.wrap({:a, 42}, %ArgumentError{}) end)
  end

  test "Ok/Error" do
    assert {:ok, 42} = Monad.wrap(42, :ok)
    assert {:ok, 42} = Monad.wrap(42, {:ok, :blah})
    assert {:error, 42} = Monad.wrap(42, :error)
    assert {:error, 42} = Monad.wrap(42, {:error, :blah})

    assert {:ok, 42} = Monad.flat_map({:ok, 21}, &{:ok, &1*2})
    assert nil == Monad.flat_map(:ok, &(&1))

    assert {:error, 42} = Monad.flat_map({:error, 42}, &{:ok, &1*2})
    assert :error = Monad.flat_map(:error, &{:ok, &1*2})

    assert {:ok, 2} =
      1
      |> Monad.wrap(:ok)
      |> Monad.flat_map(&{:ok, &1 * 2})

    assert {:error, 1} =
      1
      |> Monad.wrap(:error)
      |> Monad.flat_map(&{:ok, &1 * 2})
  end
end
