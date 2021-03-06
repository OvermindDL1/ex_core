defmodule ExCore.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_core,
      version: "0.1.0",
      elixir: "~> 1.6-dev",
      start_permanent: Mix.env == :prod,
      compilers: Mix.compilers ++ [:protocol_ex],
      deps: deps(),
      aliases: aliases(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        # :logger,
      ],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:protocol_ex, path: "../protocol_ex"},
      {:stream_data, "~> 0.3.0"},
      # Development only
      {:cortex, "~> 0.2.0", only: [:dev, :test]},
      {:benchee, "~> 0.9.0", only: [:dev, :test]},
    ]
  end

  defp aliases do
    [
      bench: &bench/1
    ]
  end

  defp bench(arglist)
  defp bench([]) do
    Mix.shell.info "Pass in the name of the benchmark(s) to run"
  end
  defp bench(benches) do
    Enum.map(benches, fn bench ->
      Mix.Task.reenable(:run)
      Mix.Tasks.Run.run(["bench/#{bench}_bench.exs"])
    end)
  end
end
