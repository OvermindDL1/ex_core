import ProtocolEx

## List

defimpl_ex Map, %{}, for: ExCore.Access do
  defmacro fetch(object, key) do
    quote do
      case unquote(object) do
        %{__struct__: struct} = s ->
          try do struct.fetch(s, unquote(key))
          rescue e in UndefinedFunctionError ->
            e = %{e | reason: "#{inspect struct} does not implement the ExCore.Access protocol or the Access behaviour"}
            reraise(e, System.stacktrace())
          end
        %{^unquote(key) => value} -> {:ok, value}
        _ -> :error
      end
    end
  end

  defmacro fetch_and_update(object, key, function) do
    quote do
      case unquote(object) do
        %{^unquote(key) => value} -> {:ok, value}
        _ -> :error
      end
      |> unquote(function).()
      |> case do
        :error -> :maps.remove(unquote(key), unquote(object))
        {:ok, value} -> :maps.put(unquote(key), value, unquote(object))
      end
    end
  end
end
