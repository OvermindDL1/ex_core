import ProtocolEx

## Lens support

defimpl_ex Lens, _, for: ExCore.Access do
  @priority 65538

  @inline; def fetch(object, {ExCore.Access, key}), do: fetch(object, key)
  @inline; def fetch(object, {ExCore.Access, left, right}) do
    case fetch(object, left) do
      :error -> :error
      {:ok, value} -> fetch(value, right)
    end
  end
  @inline; def fetch(object, {ExCore.Access, key, :default, defaul}) do
    case fetch(object, key) do
      :error -> {:ok, defaul}
      {:ok, _value} = ok -> ok
    end
  end

  @inline; def get(object, {ExCore.Access, key}), do: get(object, key)
  @inline; def get(object, {ExCore.Access, left, right}) do
    get(get(object, left), right)
  end
  @inline; def get(object, {ExCore.Access, key, :default, defaul}) do
    get(object, key) || defaul
  end

  @inline; def get(object, default, {ExCore.Access, key}), do: get(object, key, default)
  @inline; def get(object, default, {ExCore.Access, _, _} = key), do: get(object, key, default)
  @inline; def get(object, default, {ExCore.Access, _, _, _} = key), do: get(object, key, default)
  @inline; def get(object, {ExCore.Access, key}, default), do: get(object, key, default)
  @inline; def get(object, {ExCore.Access, left, right}, default) do
    case get(object, left, default) do
      ^default -> default
      value -> get(value, right, default)
    end
  end
  @inline; def get(object, {ExCore.Access, key, :default, defaul}, _default) do
    get(object, key, defaul)
  end

  @inline; def fetch_and_update(object, function, {ExCore.Access, key}), do: fetch_and_update(object, key, function)
  @inline; def fetch_and_update(object, function, {ExCore.Access, _, _} = key), do: fetch_and_update(object, key, function)
  @inline; def fetch_and_update(object, function, {ExCore.Access, _, _, _} = key), do: fetch_and_update(object, key, function)
  @inline; def fetch_and_update(object, {ExCore.Access, key}, function), do: fetch_and_update(object, key, function)
  @inline; def fetch_and_update(object, {ExCore.Access, left, right}, function) do
    fetch_and_update(object, left, fn
      :error -> :error
      {:ok, value} -> fetch_and_update(value, right, function)
    end)
  end
  @inline; def fetch_and_update(object, {ExCore.Access, key, :default, defaul}, function) do
    fetch_and_update(object, key, fn
      :error -> function.(defaul)
      {:ok, _value} = ok -> function.(ok)
    end)
  end

  @inline; def get_and_update(object, function, {ExCore.Access, key}), do: get_and_update(object, key, function)
  @inline; def get_and_update(object, function, {ExCore.Access, _, _} = key), do: get_and_update(object, key, function)
  @inline; def get_and_update(object, function, {ExCore.Access, _, _, _} = key), do: get_and_update(object, key, function)
  @inline; def get_and_update(object, {ExCore.Access, key}, function), do: get_and_update(object, key, function)
  @inline; def get_and_update(object, {ExCore.Access, left, right}, function) do
    get_and_update(object, left, fn
      nil -> nil
      value -> get_and_update(value, right, function)
    end)
  end
  @inline; def get_and_update(object, {ExCore.Access, key, :default, defaul}, function) do
    get_and_update(object, key, fn
      nil -> function.(defaul)
      value -> function.(value)
    end)
  end

  @inline; def get_and_update(object, default, function, {ExCore.Access, key}), do: get_and_update(object, key, default, function)
  @inline; def get_and_update(object, default, function, {ExCore.Access, _, _} = key), do: get_and_update(object, key, default, function)
  @inline; def get_and_update(object, default, function, {ExCore.Access, _, _, _} = key), do: get_and_update(object, key, default, function)
  @inline; def get_and_update(object, {ExCore.Access, key}, default, function), do: get_and_update(object, key, default, function)
  @inline; def get_and_update(object, {ExCore.Access, left, right}, default, function) do
    get_and_update(object, left, default, fn
      ^default -> default
      value -> get_and_update(value, right, function)
    end)
  end
  @inline; def get_and_update(object, {ExCore.Access, key, :default, defaul}, _default, function) do
    get_and_update(object, key, defaul, function)
  end

  @inline; def set(object, value, {ExCore.Access, key}), do: set(object, key, value)
  @inline; def set(object, {ExCore.Access, key}, value), do: set(object, key, value)
  @inline; def set(object, {ExCore.Access, left, right}, value) do
    fetch_and_update(object, left, fn
      :error -> :error
      {:ok, valueo} -> set(valueo, right, value)
    end)
  end
  @inline; def set(object, {ExCore.Access, key, :default, _defaul}, value) do
    set(object, key, value)
  end

  @inline; def pop(object, {ExCore.Access, key}), do: pop(object, key)
  @inline; def pop(object, {ExCore.Access, left, right}) do
    fetch_and_update(object, left, fn
      :error -> :error
      {:ok, value} -> pop(value, right)
    end)
  end
  @inline; def pop(object, {ExCore.Access, key, :default, _defaul}) do
    pop(object, key)
  end
end

## Basic types

defimpl_ex Map, %{}, for: ExCore.Access, inline: [fetch: 2, fetch_and_update: 3] do
  @priority -65537
  def fetch(%{__struct__: struct} = s, key) do
    try do struct.fetch(s, key)
    rescue e in UndefinedFunctionError ->
      e = %{e | reason: "#{inspect struct} does not implement the ExCore.Access protocol or the Access behaviour"}
      reraise(e, System.stacktrace())
    end
  end
  def fetch(%{} = map, key) do
    case map do
      %{^key => value} -> {:ok, value}
      _ -> :error
    end
  end

  def fetch_and_update(%{__struct__: struct} = s, key, function) do
    try do
      function.(struct.fetch(s, key))
      |> case do
        {:ok, value} -> :maps.put(key, value, s)
        :error -> :maps.remove(key, s)
      end
    rescue e in UndefinedFunctionError ->
      e = %{e | reason: "#{inspect struct} does not implement the ExCore.Access protocol or the Access behaviour"}
      reraise(e, System.stacktrace())
    end
  end
  def fetch_and_update(%{} = map, key, function) do
    map
    |> case do
      %{^key => value} -> {:ok, value}
      _ -> :error
    end
    |> function.()
    |> case do
      {:ok, value} -> :maps.put(key, value, map)
      :error -> :maps.remove(key, map)
    end
  end
end
