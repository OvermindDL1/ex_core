

defmodule Helpers do
  def do_flat_map({k, v}), do: %{k => v, v => k}
  def do_flat_map(v), do: [v, v]

  def do_flat_map_wrong({k, v}), do: [{k, v}, {v, k}]
  def do_flat_map_wrong(v), do: [v, v]
end

inputs = %{
  "List"     => [:a, :b, :c, :d],
  "Map"      => %{a: 1, b: 2, c: 3, d: 4},
  "ValueMap" => ExCore.Monad.wrap(42, %{}),
}


actions = %{
  "Elixir.Enum.flat_map" => fn input -> Enum.flat_map(input, &Helpers.do_flat_map/1) end,
  "Elixir.Enum.flat_map_wrong" => fn input -> Enum.flat_map(input, &Helpers.do_flat_map_wrong/1) end,
  "ExCore.Monad.flat_map" => fn input -> ExCore.Monad.flat_map(input, &Helpers.do_flat_map/1) end,
}


Benchee.run actions, inputs: inputs, time: 5, warmup: 5, print: %{fast_warning: false}
