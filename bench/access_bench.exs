
inputs = %{
  "Map" => %{a: 1, b: 2, c: 3, d: 4},
}


actions = %{
  "Elixir.Access.fetch" => &Access.fetch(&1, :b),
  "ExCore.Access.fetch" => &ExCore.Access.fetch(&1, :b),
}


Benchee.run actions, inputs: inputs, time: 10, warmup: 5, print: %{fast_warning: false}
