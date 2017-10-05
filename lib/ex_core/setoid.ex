import ProtocolEx
defprotocol_ex ExCore.Setoid, as: o do
  require ExCore.StreamDataGenerator

  def equals(o, n), do: o === n

  deftest equality do
    generator = ExCore.StreamDataGenerator.generator(ExCore.Setoid, __MODULE__, [])
    ref = make_ref()
    StreamData.check_all(generator, [initial_seed: :os.timestamp()], fn v ->
      if equals(v, v) and not equals(v, ref) do
        {:ok, v}
      else
        {:error, v}
      end
    end)
  end
end
