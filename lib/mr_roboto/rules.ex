defmodule MrRoboto.Rules do
  @moduledoc """
  The Rules module defines the rules for a user-agent.

  The Rules module defines the MrRoboto.Rules struct which provides a convenient
  way to track the directives for a user agent

  The Rules module also provides functionality for checking whether a path is
  legal for a rule set
  """

  defstruct user_agent: "", allow: [], disallow: [], crawl_delay: 1000

  @doc """
  Sets the *Crawl Delay* for the `user-agent`

  Returns an updated `MrRoboto.Rules` struct

  ## Examples

    ```
    iex> rule = %MrRoboto.Rules{user_agent: "*", allow: ["/"], disallow: [], crawl_delay: 1000}
    ...> MrRoboto.Rules.set_delay(rule, 2000)
    %MrRoboto.Rules{user_agent: "*", allow: ["/"], disallow: [], crawl_delay: 2000}
    ```

  """
  def set_delay(rule, frequency) do
    struct(rule, crawl_delay: frequency)
  end

  @doc """
  Determines whether the specified `path` is allowed by the given `rule`

  Returns `true` or `false`

  ## Examples

  When checking a path and a rule the determination is made based on the directive
  with the longest match.  For example if `"/foo"` is allowed but `"/foo/bar"` is
  disallowed a __path__ value of `"/foo/bar/baz"` would not be permitted.

  ```
  iex> rule = %Rules{user_agent: "*", allow: ["/foo"], disallow: ["/foo/bar"]}
  ...> Rules.permitted? rule, "/foo/bar/baz"
  false
  ```

  Wildcard matches are counted as if they were normal directives.  So for example,
  `"/foo*bar"` would have an equal weight as `"/foo/bar"`.  In this case the
  response will be `:ambiguous` and it is up to the caller to decide how to
  proceed.

  ```
  iex> rule = %Rules{user_agent: "*", allow: ["/foo*bar"], disallow: ["/foo/bar"]}
  ...> Rules.permitted? rule, "/foo/bar"
  :ambiguous
  ```

  `$` terminated directives are supported as well.  When matching against a `$`
  terminated directive the dollar sign is ignored.  However when considering
  match length it is not.

  ```
  iex> rule = %Rules{user_agent: "*", allow: ["/foo"], disallow: ["/*.php$"]}
  ...> Rules.permitted? rule, "/hello/world.php"
  false
  ```

  """
  def permitted?(rule, path) do
    allow_check = Task.async(__MODULE__, :matching_allow, [rule, path])

    disallow = matching_disallow(rule, path)
    allow = Task.await(allow_check)

    case byte_size(allow) do
      a_size when a_size > byte_size(disallow) ->
        true
      a_size when a_size < byte_size(disallow) ->
        false
      _ ->
        :ambiguous
    end
  end

  def matching_allow(rule, path) do
    longest_match rule.allow, path, ""
  end

  def matching_disallow(rule, path) do
    longest_match rule.disallow, path, ""
  end

  @doc """
  Determines the direction to walk the path for the given directive

  Returns `:forwards` or `:backwards`

  ## Examples

  As per Google's documentation [here](https://developers.google.com/webmasters/control-crawl-index/docs/robots_txt#example-path-matches) a directive ending with `$` endicates that the pattern is matched against the end of the path.

  ```
  iex> MrRoboto.Rules.match_direction "/*.php$"
  :backwards
  ```
  ```
  iex> MrRoboto.Rules.match_direction "/foo/"
  :forwards
  ```

  """
  def match_direction(directive) do
    case :binary.last(directive) do
      ?$ ->
        :backwards
      _ ->
        :forwards
    end
  end

  @doc """
  Finds the longest directive which matches the given path.

  Returns a single directive `binary`.

  ## Examples

  In the case of multiple patterns which match.  Especially when those matches belong to both `Allow` and `Disallow` directives. It is necessary to pick a winner.  This is done by finding the longest (most specific) directive that matches the path.

  ```
  iex> directives = ["/", "/foo/bar", "/foo"]
  ...> path = "/foo/bar"
  ...> MrRoboto.Rules.longest_match directives, path, ""
  "/foo/bar"
  ```

  """
  def longest_match(directives, path, longest)
  def longest_match([], _path, longest), do: longest
  def longest_match([directive | rest], path, longest) do
    {norm_dir, norm_path} = normalize(directive, path)
    matches = directive_applies? norm_dir, norm_path

    if matches && (byte_size(directive) > byte_size(longest)) do
      longest_match rest, path, directive
    else
      longest_match rest, path, longest
    end
  end

  defp normalize(directive, path) do
    directive
    |> match_direction
    |> case do
      :forwards ->
        {directive, path}
      :backwards ->
        <<_ :: size(8), rev_dir :: binary>> = String.reverse(directive)
        {rev_dir, String.reverse(path)}
    end
  end

  @doc """
  Determines whether the given directive applies to the given path.

  Returns `true` or `false`

  ## Examples

  The most straightforward case involves vanilla paths.  As illustrated below the directive is matched character by character until there is a discrepency or the directive is exhausted.  This means that in the case of a directive ending with `$` the directive and path must be reversed before being checked.

  ```
  iex> MrRoboto.Rules.directive_applies? "/foo", "/foo/bar"
  true

  iex> MrRoboto.Rules.directive_applies? "/foo/bar", "/hello/bar"
  false
  ```

  It is also possible to check a directive containing one or more wildcards

  ```
  iex> MrRoboto.Rules.directive_applies? "/foo*bar", "/foo/hello/world/bar"
  true
  ```

  ```
  iex> MrRoboto.Rules.directive_applies? "/f*b*", "/foo/bar.html"
  true
  ```

  """
  def directive_applies?(remaining_directive, remaining_path)
  def directive_applies?("", _remaining_path), do: true
  def directive_applies?(_remaining_directive, ""), do: false
  def directive_applies?(<<d :: size(8), d_rest :: binary>>, <<p :: size(8), p_rest :: binary>>) do
    case d do
      ?* ->
        case handle_wildcard(d_rest, p_rest) do
          {:ok, directive, path} ->
            directive_applies? directive, path
          {:error, :exhausted} ->
            false
        end
      ^p ->
        directive_applies? d_rest, p_rest
      _ ->
        false
    end
  end

  defp handle_wildcard("", _remaining_path), do: {:ok, "", ""}
  defp handle_wildcard(<<target :: size(8), remaining_directive :: binary>>, path) do
    case consume_until(path, target) do
      {:ok, remaining_path} ->
        {:ok, remaining_directive, remaining_path}
      _ ->
        {:error, :exhausted}
    end
  end

  defp consume_until("", _target), do: {:error, :exhausted}
  defp consume_until(<<char :: size(8), rest:: binary>>, target) do
    case char do
      ^target ->
        {:ok, rest}
      _ ->
        consume_until rest, target
    end
  end
end
