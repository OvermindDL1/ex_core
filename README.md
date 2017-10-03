# ExCore

**TODO: Add description**

## Installation

The package can be installed by adding `ex_core` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_core, "~> 0.1.0"},
  ]
end
```

The activate the protocol_ex compiler by adding it to your compiler list in your `mix.exs` file:

```elixir
def project do
  [
    # ...
    compilers: Mix.compilers ++ [:protocol_ex],
    # ...
  ]
end
```

Documentation can be found at [https://hexdocs.pm/ex_core](https://hexdocs.pm/ex_core).
