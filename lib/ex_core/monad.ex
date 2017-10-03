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
end
