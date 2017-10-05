import ProtocolEx

defimpl_ex Any, Any, for: ExCore.StreamDataGenerator do
  defmacro generator(id, opts) do
    quote do
      _ = unquote(id)
      _ = unquote(opts)
      any = [
        StreamData.binary(),
        StreamData.integer(),
        StreamData.uniform_float(),
        StreamData.list_of(StreamData.integer()),
      ]

      StreamData.one_of([StreamData.map_of(StreamData.one_of(any), StreamData.one_of(any), 25) | any])
    end
  end
end

defimpl_ex Integer, Integer, for: ExCore.StreamDataGenerator do
  defmacro generator(id, opts) do
    quote do
      _ = unquote(id)
      _ = unquote(opts)
      StreamData.integer()
    end
  end
end

defimpl_ex Float, Float, for: ExCore.StreamDataGenerator do
  defmacro generator(id, opts) do
    quote do
      _ = unquote(id)
      _ = unquote(opts)
      StreamData.uniform_float()
      |> StreamData.map(&(&1 * 99999999))
    end
  end
end

defimpl_ex Map, Map, for: ExCore.StreamDataGenerator do
  defmacro generator(id, opts) do
    quote do
      _ = unquote(id)
      _ = unquote(opts)
      data = ExCore.StreamDataGenerator.Any.generator([], [])
      StreamData.map_of(data, data, 25)
    end
  end
end

defimpl_ex EmptyList, EmptyList, for: ExCore.StreamDataGenerator do
  defmacro generator(id, opts) do
    quote do
      _ = unquote(id)
      _ = unquote(opts)
      StreamData.constant([])
    end
  end
end

defimpl_ex List, List, for: ExCore.StreamDataGenerator do
  defmacro generator(id, opts) do
    quote do
      _ = unquote(id)
      _ = unquote(opts)
      data = StreamData.one_of([StreamData.binary(), StreamData.integer()])
      StreamData.list_of(data)
    end
  end
end

defimpl_ex Tuple, Tuple, for: ExCore.StreamDataGenerator do
  defmacro generator(id, opts) do
    quote do
      _ = unquote(id)
      _ = unquote(opts)
      data = StreamData.one_of([StreamData.binary(), StreamData.integer()])
      t0 = StreamData.tuple({})
      t1 = StreamData.tuple({data})
      t2 = StreamData.tuple({data, data})
      t3 = StreamData.tuple({data, data, data})
      t4 = StreamData.tuple({data, data, data, data})
      t5 = StreamData.tuple({data, data, data, data, data})
      t6 = StreamData.tuple({data, data, data, data, data, data})
      t7 = StreamData.tuple({data, data, data, data, data, data, data})
      t8 = StreamData.tuple({data, data, data, data, data, data, data, data})
      StreamData.one_of([t0, t1, t2, t3, t4, t5, t6, t7, t8])
    end
  end
end

defimpl_ex OkValue, OkValue, for: ExCore.StreamDataGenerator do
  defmacro generator(id, opts) do
    quote do
      _ = unquote(id)
      _ = unquote(opts)
      data = ExCore.StreamDataGenerator.Any.generator([], [])
      StreamData.tuple({:ok, data})
    end
  end
end

defimpl_ex Ok, Ok, for: ExCore.StreamDataGenerator do
  defmacro generator(id, opts) do
    quote do
      _ = unquote(id)
      _ = unquote(opts)
      StreamData.constant(:ok)
    end
  end
end

defimpl_ex ErrorValue, ErrorValue, for: ExCore.StreamDataGenerator do
  defmacro generator(id, opts) do
    quote do
      _ = unquote(id)
      _ = unquote(opts)
      data = ExCore.StreamDataGenerator.Any.generator([], [])
      StreamData.tuple({:error, data})
    end
  end
end

defimpl_ex Error, Error, for: ExCore.StreamDataGenerator do
  defmacro generator(id, opts) do
    quote do
      _ = unquote(id)
      _ = unquote(opts)
      StreamData.constant(:error)
    end
  end
end
