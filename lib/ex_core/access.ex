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
    get_and_update(object, key, function, nil)
  end

  def get_and_update(object, key, function, default) when is_function(function, 1) do
    fetch_and_update(object, key, fn
      {:ok, value} -> function.(value)
      :error -> function.(default)
    end)
  end

  def set(object, key, value) do
    fetch_and_update(object, key, fn _ -> {:ok, value} end)
  end
end
