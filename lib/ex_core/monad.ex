import ProtocolEx
defprotocol_ex ExCore.Monad, as: monad do
  require ExCore.StreamDataGenerator

  def wrap(value, monad)
  def flat_map(monad, fun) when is_function(fun, 1)

  deftest neutrality do
    generator = ExCore.StreamDataGenerator.generator(Any, [])
    ident_wrap = &wrap(&1, nil)
    StreamData.check_all(generator, [initial_seed: :os.timestamp()], fn v ->
      wrap(v, nil) === flat_map(wrap(v, nil), ident_wrap) && {:ok, v} || {:error, v}
    end)
  end

  deftest succession_ordering do
    generator = ExCore.StreamDataGenerator.generator(ExCore.Monad, __MODULE__, [])
    f = fn x -> wrap({x, 1}, nil) end
    g = fn {x, 1} -> wrap(x, nil) end
    StreamData.check_all(generator, [initial_seed: :os.timestamp()], fn v ->
      if flat_map(flat_map(wrap(v, nil), f), g) === flat_map(wrap(v, nil), fn x -> flat_map(f.(x), g) end) do
        {:ok, v}
      else
        {:error, v}
      end
    end)
  end
end
