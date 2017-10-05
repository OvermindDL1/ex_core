defmodule ExCore.AccessTest do
  use ExUnit.Case
  alias ExCore.Access
  # doctest Access

  test "Map" do
    assert 42 === Access.get(%{a: 42}, :a)
    assert nil === Access.get(%{a: 42}, :b)
    assert :error === Access.get(%{a: 42}, :b, :error)
    assert %{a: 21} === Access.set(%{a: 42}, :a, 21)
  end

end
