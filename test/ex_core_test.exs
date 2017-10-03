defmodule ExCoreTest do
  use ExUnit.Case
  doctest ExCore

  test "greets the world" do
    assert ExCore.hello() == :world
  end
end
