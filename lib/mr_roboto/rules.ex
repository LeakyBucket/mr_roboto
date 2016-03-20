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
end
