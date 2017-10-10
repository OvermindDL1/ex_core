defmodule ExCore.Comprehension do

  @doc ~S"""

  iex> comp do
  ...>   x <- list [1, 2, 3]
  ...>   x
  ...> end
  [1, 2, 3]

  iex> comp do
  ...>   x <- list [1, 2, 3]
  ...>   x * 2
  ...> end
  [2, 4, 6]

  iex> l = [1, 2, 3]
  iex> comp do
  ...>   x <- list [1, 2, 3]
  ...>   y <- list l
  ...>   x * y
  ...> end
  [1, 2, 3, 2, 4, 6, 3, 6, 9]

  """
  defmacro comp(bodies) do
    {name, meta, external_vars, _body, into} = comp_definitions = build_comp(__CALLER__, bodies)
    Module.put_attribute(__CALLER__.module, :excore_comprehensions, comp_definitions)
    {String.to_atom(name), meta, external_vars ++ [elem(into, 1)]}
    |> mark_generated()
  end


  defmacro __using__([]) do
    quote do
      @before_compile ExCore.Comprehension
      import ExCore.Comprehension, only: [comp: 1]
      Module.register_attribute __MODULE__, :excore_comprehensions, accumulate: true, persist: false
    end
  end


  defmacro __before_compile__(env) do
    case Module.get_attribute(env.module, :excore_comprehensions) do
      nil -> nil
      [] -> nil
      [_ | _] = exprs ->
        quote do
          (unquote_splicing(Enum.map(exprs, fn {name, meta, external_vars, body, into} ->
            gen_comp_function(env, name, meta, external_vars, body, into)
          end)))
        end |> case do ast -> IO.puts(Macro.to_string(ast)); ast end
    end
    |> mark_generated()
  end


  defp build_comp(env, bodies) do
    name = "$comp_#{elem(env.function, 0)}_#{elem(env.function, 1)}_#{env.line}"

    {do_body, [] = _bodies} = Keyword.pop(bodies, :do)

    {do_body, external_vars, into} =
      do_body
      |> normalize_bodylist()
      |> comp_body(env)

    external_vars = Map.values(external_vars)

    {name, Macro.Env.location(env), external_vars, do_body, into}
  end


  defp normalize_bodylist(body)
  defp normalize_bodylist({:__block__, _meta, bodylist}), do: bodylist
  defp normalize_bodylist(expr), do: [expr]


  defp comp_body(exprs, %{} = env), do: comp_body(env, 0, %{}, exprs)

  defp comp_body(env, depth, created_vars, exprs)
  defp comp_body(_env, _depth, _created_vars, []), do: {[], [], {:list, []}} # Default `into` is a list
  defp comp_body(env, depth, created_vars, [{:=, _meta, [matcher, expr]} = ast | exprs]) do
    created_vars = add_created_vars(created_vars, matcher)
    external_vars = get_external_vars_needed(created_vars, expr)
    {exprs, more_external_vars, into} = comp_body(env, depth + 1, created_vars, exprs)
    {
      [{:lit, ast}] ++ exprs,
      Map.merge(external_vars, more_external_vars),
      into,
    }
  end
  defp comp_body(env, depth, created_vars, [{:<-, meta, [head, {type, _, type_exprs}]} | exprs]) do
    created_vars = add_created_vars(created_vars, head)
    {expr, external_vars} = comp_expr(env, depth + 1, created_vars, meta, head, type, type_exprs|>IO.inspect(label: :Blah))
    {exprs, more_external_vars, into} = comp_body(env, depth + 1, created_vars, exprs)
    {
      expr ++ exprs,
      Map.merge(external_vars, more_external_vars),
      into,
    }
  end
  defp comp_body(env, _depth, _created_vars, [{:<-, meta, [head, unknown_comp]} | _exprs]) do
    throw {:comp, :invalid_comp_expression, Macro.Env.location(env), [line: meta[:line]], head, unknown_comp}
  end
  defp comp_body(env, _depth, _created_vars, [{:<-, meta, _exprs} = ast]) do
    throw {:comp, :invalid_final_expression, Macro.Env.location(env), [line: meta[:line]], ast}
  end
  defp comp_body(env, _depth, created_vars, [{:->, meta, [[final], into]} = ast]) do
    external_vars = get_external_vars_needed(created_vars, final)
    {[{:lit, final}], external_vars, case into do
      [] -> {:list, []}
      [_ | _] = list -> {:list, quote(do: :lists.reverse(unquote(list)))}
      {:%{}, _, []} = map -> {:map, []}
      {:%{}, _, _} = map -> {:map, quote(do: :maps.to_list(unquote(map)))}
      unhandled -> throw {:comp, :invalid_into_expression, Macro.Env.location(env), [line: meta[:line]], ast}
    end}
  end

  defp comp_body(_env, _depth, created_vars, [final]) do
    external_vars = get_external_vars_needed(created_vars, final)
    {[{:lit, final}], external_vars, {:list, []}} # Default `into` is a list
  end


  defp comp_expr(env, depth, created_vars, meta, head, type, exprs)
  defp comp_expr(_env, depth, created_vars, meta, head, :list, [list]) do
    {
      [{:newfunction, :list, depth + 1, head, meta, list}],
      get_external_vars_needed(created_vars, list),
    }
  end
  defp comp_expr(env, _depth, _created_vars, meta, _head, type, exprs) do
    throw {:comp, :invalid_comp_type, Macro.Env.location(env), [line: meta[:line]], type, exprs}
  end


  defp get_external_vars_needed(created_vars, expr) do
    {_ast, acc} = Macro.prewalk(expr, %{}, fn
      ({var, _meta, scope} = ast, vars) when is_atom(var) and is_atom(scope) ->
        case created_vars do
          %{^var => _} -> {ast, vars}
          _ -> {ast, Map.put(vars, var, ast)}
        end
      (ast, vars) -> {ast, vars}
    end)
    acc
  end


  defp add_created_vars(created_vars, expr) do
    {_ast, acc} = Macro.prewalk(expr, created_vars, fn
      ({var, _meta, scope} = ast, created_vars) when is_atom(var) and is_atom(scope) ->
        {ast, Map.put(created_vars, var, ast)}
      (ast, created_vars) -> {ast, created_vars}
    end)
    acc
  end


  ## Generating functions

  defp gen_comp_function(env, name, meta, external_vars, body, into) do
    {funs, body} = gen_comp_functions(env, name, into, external_vars, body)
    acc = Macro.var(:acc, nil)
    fun =
      {:defp,
      meta,
      [
        {String.to_atom(name), meta, external_vars ++ [acc]},
        [do: quote do
          unquote(into_end(into, {:__block__, meta, body}))
        end],
      ],
    }
    quote do
      unquote(fun)
      (unquote_splicing(funs))
    end
  end


  defp gen_comp_functions(env, name, into, external_vars, body)
  defp gen_comp_functions(_env, _name, _into, _external_vars, []), do: {[], []}
  defp gen_comp_functions(env, name, into, external_vars, [{:newfunction, :list, depth, head, meta, list} | body]) do
    my_name = String.to_atom("#{name}_#{depth}")
    {matcher, guards} = decompose_head(head)
    new_vars = Map.values(add_created_vars(%{}, matcher))
    new_external_vars = external_vars ++ new_vars
    {funs, body} = gen_comp_functions(env, name, into, new_external_vars, body)
    acc = Macro.var(:acc, nil)
    fun =
      case funs do
        [] ->
          quote do
            defp unquote(my_name)(unquote_splicing(external_vars), unquote(acc), []) do
              unquote(mark_all_unused(external_vars))
              unquote(acc)
            end
            defp unquote(my_name)(unquote_splicing(external_vars), unquote(acc), [unquote(matcher) | list]) when unquote(guards) do
              unquote(mark_all_unused(external_vars))
              unquote(acc) = unquote(gen_append(into, quote(do: (unquote_splicing(body))), acc))
              unquote(my_name)(unquote_splicing(external_vars), unquote(acc), list)
            end
            defp unquote(my_name)(unquote_splicing(external_vars), unquote(acc), [_ | list]) do
              unquote(my_name)(unquote_splicing(external_vars), unquote(acc), list)
            end
          end
        [_ | _] ->
          quote do
            defp unquote(my_name)(unquote_splicing(external_vars), unquote(acc), []) do
              unquote(mark_all_unused(external_vars))
              unquote(acc)
            end
            defp unquote(my_name)(unquote_splicing(external_vars), unquote(acc), [unquote(matcher) | list]) when unquote(guards) do
              unquote(acc) = (unquote_splicing(body))
              unquote(my_name)(unquote_splicing(external_vars), unquote(acc), list)
            end
            defp unquote(my_name)(unquote_splicing(external_vars), unquote(acc), [_ | list]) do
              unquote(my_name)(unquote_splicing(external_vars), unquote(acc), list)
            end
          end
      end
    ast = {my_name, meta, external_vars ++ [acc, list]}
    {[fun | funs], [ast]}
  end
  defp gen_comp_functions(env, name, into, external_vars, [{:lit, expr} | body]) do
    {funs, body} = gen_comp_functions(env, name, into, external_vars, body)
    {funs, [expr | body]}
  end
  defp gen_comp_functions(_env, name, _into, external_vars, [body | _rest]) do
    throw {:UNHANDLED_COMP_GEN, name, external_vars, body}
  end


  defp decompose_head(head)
  defp decompose_head({:when, _, [matcher, guards]}), do: {matcher, guards}
  defp decompose_head(head), do: {head, true}

  defp gen_append(into, value, acc)
  defp gen_append({:list, _list}, value, acc) do
    quote(do: [unquote(value) | unquote(acc)])
  end
  defp gen_append({:map, _map}, value, acc) do
    # quote(do: :maps.merge(unquote(acc), unquote(value)))
    quote(do: [unquote(value) | unquote(acc)]) # :maps.put(elem(unquote(value), 0), elem(unquote(value), 1), unquote(acc)))
  end

  # defp into_start(into)
  # defp into_start({:list, []}), do: []
  # defp into_start({:list, [_] = list}), do: list
  # defp into_start({:list, list}), do: quote(do: :lists.reverse(unquote(list)))
  # defp into_start({:map, {%{}, _, []}}), do: []
  # defp into_start({:map, map}), do: quote(do: :maps.to_list(unquote(map)))

  defp into_end(into, acc)
  defp into_end({:list, _}, acc), do: quote(do: :lists.reverse(unquote(acc)))
  defp into_end({:map, _}, acc), do: quote(do: :maps.from_list(unquote(acc)))

  defp mark_generated(expr) do
    Macro.prewalk(expr, fn
      {l, meta, r} -> {l, [generated: true] ++ meta, r}
      ast -> ast
    end)
  end

  defp mark_all_unused([]), do: nil
  defp mark_all_unused(external_vars) do
    {:__block__, [], Enum.map(external_vars, &quote(do: _ = unquote(&1)))}
  end

end
