

defmodule Helpers do
  use ExCore.Comprehension

  # map * 2

  def elixir_0(l) do
    for\
      x <- l,
      do: x * 2
  end

  def ex_core_0(l) do
    comp do
      x <- list l
      x * 2
    end
  end

  # Into map value to value*2 after adding 1

  def elixir_1(l) do
    for\
      x <- l,
      y = x + 1,
      into: %{},
      do: {x, y * 2}
  end

  def ex_core_1(l) do
    comp do
      x <- list l
      y = x + 1
      {x, y * 2} -> %{}
    end
  end
end

inputs = %{
  "List - 10000 - map*2" => {:lists.seq(0, 10000), &Helpers.elixir_0/1, &Helpers.ex_core_0/1},
  "List - 10000 - into map +1 even *2" => {:lists.seq(0, 10000), &Helpers.elixir_1/1, &Helpers.ex_core_1/1},
}


actions = %{
  "Elixir.for"  => fn {input, elx, _core} -> elx.(input) end,
  "ExCore.comp" => fn {input, _elx, core} -> core.(input) end,
}


Benchee.run actions, inputs: inputs, time: 5, warmup: 5, print: %{fast_warning: false}
