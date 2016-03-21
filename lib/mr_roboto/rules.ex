defmodule MrRoboto.Rules do
  @moduledoc """
  The Rules module defines the rules for a user-agent.

  The Rules module defines the MrRoboto.Rules struct and a few functions which allow querying the rule set along with one function for setting the `crawl_delay`.
  """

  defstruct user_agent: "", allow: [], disallow: [], crawl_delay: 1000

  @doc """
  Sets the *Crawl Delay* for the `user-agent`

  Returns an updated `MrRoboto.Rules` struct

  ## Examples

    iex> rule = %MrRoboto.Rules{user_agent: "*", allow: ["/"], disallow: [], crawl_delay: 1000}
    ...> MrRoboto.Rules.set_delay(rule, 2000)
    %MrRoboto.Rules{user_agent: "*", allow: ["/"], disallow: [], crawl_delay: 2000}

  """
  def set_delay(rule, frequency) do
    struct(rule, crawl_delay: frequency)
  end

  @doc """
  Determines whether the specified `path` is allowed by the given `rule`

  Returns `true` or `false`
  """
  def allowed?(rule, path) do # Collect allow and disallow matches, the type with the longest match wins

  end

  @doc """
  Determines the direction to walk the path for the given directive

  Returns `:forwards` or `:backwards`

  ## Examples

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
    matches = case match_direction(directive) do
                :forwards ->
                  directive_applies? directive, path
                :backwards ->
                  <<_ :: size(8), rev_dir :: binary>> = reverse(directive)
                  rev_path = reverse(path)
                  directive_applies? rev_dir, rev_path
              end

    if matches && (byte_size(directive) > byte_size(longest)) do
      longest_match rest, path, directive
    else
      longest_match rest, path, longest
    end
  end
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

  defp reverse(string), do: List.to_string(Enum.reverse to_char_list(string))
end
