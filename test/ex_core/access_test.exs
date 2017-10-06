defmodule ExCore.AccessTest do
  use ExUnit.Case
  alias ExCore.Access
  # doctest Access

  test "Map" do
    assert 42 === Access.get(%{a: 42}, :a)
    assert nil === Access.get(%{a: 42}, :b)
    assert :error === Access.get(%{a: 42}, :b, :error)
    assert %{a: 21} === Access.set(%{a: 42}, :a, 21)
  end

  test "Lens" do
    import Access, only: [lens: 1]

    o0a = %{a: 42}
    assert l0a = lens a
    assert l0b = lens [:a]
    assert 42 = l0a.get(o0a)
    assert 42 = l0b.get(o0a)

    o1a = %{a: %{b: 42}}
    assert l1a = (lens a.b)
    assert l1b = (lens [:a][:b])
    assert l1c = (lens a[:b])
    assert l1d = (lens [:a].b)
    assert l2a = (lens {:c})
    assert l2b = (lens {:c, 32})
    assert l2c = (lens {:c, %{b: 16}}.b)
    assert l2d = (lens a{:c, %{d: 12}}.d)
    assert 42 = l1a.get(o1a)
    assert 42 = l1b.get(o1a)
    assert 42 = l1c.get(o1a)
    assert 42 = l1d.get(o1a)
    assert nil == l2a.get(o1a)
    assert 32 = l2b.get(o1a)
    assert 16 = l2c.get(o1a)
    assert 12 = l2d.get(o1a)

    o2a = %{a: 21}
    o2b = %{a: %{b: 21}}
    assert l2a = (lens a)
    assert l2b = (lens a.b)
    assert l2c = (lens a{:c, %{d: 21}}.d)
    assert %{a: 42} = l2a.get_and_update(o2a, &(&1*2))
    assert %{a: %{b: 42}} = l2b.get_and_update(o2b, &(&1*2))
    assert %{a: %{b: 21, c: %{d: 42}}} = l2c.get_and_update(o2b, &(&1*2))
  end

end
