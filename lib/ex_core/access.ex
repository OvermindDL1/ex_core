import ProtocolEx
defprotocol_ex ExCore.Access, as: object do
  def fetch(object, key)

  def get(object, key), do: get(object, key, nil)

  def get(object, key, default) do
    case fetch(object, key) do
      {:ok, value} -> value
      :error -> default
    end
  end

  def fetch_and_update(object, key, function) when is_function(function, 1)

  def get_and_update(object, key, function) when is_function(function, 1) do
    get_and_update(object, key, nil, function)
  end

  def get_and_update(object, key, default, function) when is_function(function, 1) do
    fetch_and_update(object, key, fn
      {:ok, value} ->
        case function.(value) do
          nil -> :error
          value -> {:ok, value}
        end
      :error ->
        case function.(default) do
          nil -> :error
          value -> {:ok, value}
        end
    end)
  end

  def set(object, key, value) do
    fetch_and_update(object, key, fn _ -> {:ok, value} end)
  end

  def pop(object, key) do
    fetch_and_update(object, key, fn _ -> :error end)
  end

  ## Helpers

  defmacro lens(cmd) do
    lens_body(cmd)
  end

  defp lens_body(cmd)
  defp lens_body(key) when is_atom(key) do
    quote(do: {ExCore.Access, unquote(key)})
  end
  defp lens_body({:{}, _, [key]}) do
    quote(do: {ExCore.Access, unquote(key)})
  end
  defp lens_body({key, default}) do
    quote(do: {ExCore.Access, unquote(key), :default, unquote(default)})
  end
  defp lens_body([key]) do
    quote(do: {ExCore.Access, unquote(key)})
  end
  defp lens_body({key, _, scope}) when is_atom(key) and is_atom(scope) do
    quote(do: {ExCore.Access, unquote(key)})
  end
  defp lens_body({{:., _dot_meta, [Access, :get]}, _meta, [left, right]}) do
    left = lens_body(left)
    right = lens_body(right)
    quote(do: {ExCore.Access, unquote(left), unquote(right)})
  end
  defp lens_body({{:., _dot_meta, [left, right]}, _meta, []}) do
    left = lens_body(left)
    right = lens_body(right)
    quote(do: {ExCore.Access, unquote(left), unquote(right)})
  end
  defp lens_body({left, _meta, [right]}) do
    left = lens_body(left)
    right = lens_body(right)
    quote(do: {ExCore.Access, unquote(left), unquote(right)})
  end
  defp lens_body(cmd), do: throw {:Lens, :UNHANDLED_COMMAND, cmd}

  # defmacro unquote(:do)()
end

# defmodule ExCore.Lens do
#   def fetch(object, lens), do: ExCore.Access.fetch(lens, object)
#   def get(object, lens), do: ExCore.Access.get(lens, object)
# end
