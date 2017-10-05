import ProtocolEx
defprotocol_ex ExCore.StreamDataGenerator, as: id do
  def generator(id, opts), do: throw {ExCore.StreamDataGenerator, :NO_GENERATOR_FOR_ID, id, opts}

  def get_id_from_module(orig_base, full_id) do
    base = Atom.to_string(orig_base)
    size = byte_size(base)
    case Atom.to_string(full_id) do
      <<^base::binary-size(size), rest::binary>> -> String.to_existing_atom("Elixir" <> rest)
      _ -> throw {:INVALID_ID_MATCH, orig_base, full_id}
    end
  end

  def generator(base, full_id, opts) do
    generator(get_id_from_module(base, full_id), opts)
  end

  deftest generateable do
    generator = ExCore.StreamDataGenerator.generator(ExCore.StreamDataGenerator, __MODULE__, [])
    generator = StreamData.map(generator, &{&1, &1})
    StreamData.check_all(generator, [initial_seed: :os.timestamp()], fn {v0, v1} ->
      if v0 === v1 do
        {:ok, v0}
      else
        {:error, v0}
      end
    end)
  end
end
