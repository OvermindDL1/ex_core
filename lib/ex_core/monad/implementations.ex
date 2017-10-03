import ProtocolEx

## List

defimpl_ex EmptyList, [], for: ExCore.Monad do
  defmacro wrap(value, monad_type) do
    quote do
      _ = unquote(monad_type)
      [unquote(value)]
    end
  end

  defmacro flat_map(empty_list, fun) do
    quote generated: true do
      case unquote(empty_list) do
        [] -> []
        list -> ExCore.Monad.List.flat_map(list, unquote(fun))
      end
    end
  end
end


defimpl_ex List, [_ | _], for: ExCore.Monad do
  defmacro wrap(value, monad_type) do
    quote do
      _ = unquote(monad_type)
      [unquote(value)]
    end
  end

  def flat_map([], _fun), do: []
  def flat_map([head | tail], fun), do: fun.(head) ++ flat_map(tail, fun)
end


defimpl_ex Map, %{}, for: ExCore.Monad do
  @priority -16

  defmacro wrap(value, monad_type) do
    quote do
      _ = unquote(monad_type)
      case unquote(value) do
        {key, value} -> %{key => value}
        value -> %{value: value}
      end
    end
  end

  def flat_map(map, fun) do
    map
    |> :maps.to_list()
    |> flat_map(fun, %{})
  end

  defp flat_map([], _fun, returned), do: returned
  defp flat_map([element | rest], fun, returned) do
    flat_map(rest, fun, :maps.merge(returned, fun.(element)))
  end
end


defimpl_ex Struct, %{__struct__: _}, for: ExCore.Monad do
  @priority 8

  def wrap(value, monad_type) do
    raise %ProtocolEx.UnimplementedProtocolEx{proto: ExCore.Monad, name: :wrap, arity: 2, value: [value, monad_type]}
  end

  def flat_map(map, fun) do
    raise %ProtocolEx.UnimplementedProtocolEx{proto: ExCore.Monad, name: :flat_map, arity: 2, value: [map, fun]}
  end
end


defimpl_ex OkValue, {:ok, _}, for: ExCore.Monad do
  defmacro wrap(value, monad_type) do
    quote do
      _ = unquote(monad_type)
      {:ok, unquote(value)}
    end
  end

  defmacro flat_map(ok_value, fun) do
    quote do
      unquote(fun).(elem(unquote(ok_value), 1))
    end
  end
end

defimpl_ex Ok, :ok, for: ExCore.Monad do
  defmacro wrap(value, monad_type) do
    quote do
      _ = unquote(monad_type)
      {:ok, unquote(value)}
    end
  end

  defmacro flat_map(ok_value, fun) do
    quote generated: true do
      fun = unquote(fun)
      case unquote(ok_value) do
        {:ok, value} -> fun.(value)
        :ok -> fun.(nil)
      end
    end
  end
end

defimpl_ex ErrorValue, {:error, _}, for: ExCore.Monad do
  defmacro wrap(value, monad_type) do
    quote do
      _ = unquote(monad_type)
      {:error, unquote(value)}
    end
  end

  defmacro flat_map(error_value, fun) do
    quote do
      _ = unquote(fun)
      unquote(error_value)
    end
  end
end

defimpl_ex Error, :error, for: ExCore.Monad do
  defmacro wrap(value, monad_type) do
    quote do
      _ = unquote(monad_type)
      {:error, unquote(value)}
    end
  end

  defmacro flat_map(error_value, fun) do
    quote do
      _ = unquote(fun)
      unquote(error_value)
    end
  end
end
