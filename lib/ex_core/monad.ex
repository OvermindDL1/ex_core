import ProtocolEx
defprotocol_ex ExCore.Monad, as: monad do
  def wrap(value, monad)
  def flat_map(monad, fun) when is_function(fun, 1)

  deftest neutrality do
    generator = StreamData.one_of([StreamData.integer(), StreamData.binary()])
    ident_wrap = &wrap(&1, nil)
    StreamData.check_all(generator, [initial_seed: :os.timestamp()], fn v ->
      wrap(v, nil) === flat_map(wrap(v, nil), ident_wrap) && {:ok, v} || {:error, v}
    end)
  end

  deftest succesion_ordering do
    generator = StreamData.one_of([StreamData.integer()])
    f = &wrap([&1], nil)
    g = &wrap(hd(&1), nil)
    StreamData.check_all(generator, [initial_seed: :os.timestamp()], fn v ->
      if flat_map(flat_map(wrap(v, nil), f), g) === flat_map(wrap(v, nil), fn x -> flat_map(f.(x), g) end) do
        {:ok, v}
      else
        {:error, v}
      end
    end)
  end
end
