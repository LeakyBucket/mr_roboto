defmodule MrRoboto.Parser do
  @moduledoc """
  This is the Parser Module.  The functions here handle the transformation of a `robots.txt` file into `MrRoboto.Rules` structs.
  """

  alias MrRoboto.Rules

  @doc """
  Starts parsing the `body`

  Returns a list of `MrRobot.Rules` structs

  ## Examples

    iex> body = "User-agent: *\nAllow: /"
    iex> MrRoboto.Parser.start_parse body
    [%MrRoboto.Rules{user_agent: "*", allow: ["/"], disallow: [], crawl_delay: 1000}]

  """
  def start_parse(body) do
    parse body, new_block, []
  end

  @doc """
  Performs the actual robots parsing

  Returns a list of `MrRoboto.Rules` structs

  ## Examples

    iex> body = "User-agent: *"
    iex> MrRoboto.Parser.parse body, MrRoboto.Parser.new_block, []
    [%MrRoboto.Rules{user_agent: "*", allow: [], disallow: [], crawl_delay: 1000}]

    iex> body = "User-agent: *\nAllow: /\nDisallow: /foo/"
    iex> MrRoboto.Parser.parse body, MrRoboto.Parser.new_block, []
    [%MrRoboto.Rules{user_agent: "*", allow: ["/"], disallow: ["/foo/"], crawl_delay: 1000}]

  """
  def parse(binary, map, list)
  def parse("", block, results), do: build_rules(block) ++ results
  def parse(<<"#", rest :: binary>>, block, results), do: parse(consume_comment(rest), block, results)
  def parse(<<"\r\n", rest :: binary>>, block, results), do: parse(rest, block, results)
  def parse(<<"\n", rest :: binary>>, block, results), do: parse(rest, block, results)
  def parse(<<"Allow:", rest :: binary>>, block, results) do
    {name, remaining} = get_value("", rest)
    updated_block = add_allow(block, name)
    parse(remaining, updated_block, results)
  end
  def parse(<<"Disallow:", rest :: binary>>, block, results) do
    {name, remaining} = get_value("", rest)
    updated_block = add_disallow(block, name)
    parse(remaining, updated_block, results)
  end
  def parse(<<"User-agent:", rest :: binary>>, block, results) do
    case block do
      %{user_agents: _agents, allow: [], disallow: [], delay: nil} ->
        {name, remaining} = get_value("", rest)
        updated_block = add_agent(block, name)
        parse(remaining, updated_block, results)
      _ ->
        new_results = build_rules(block) ++ results
        {name, remaining} = get_value("", rest)
        updated_block = add_agent(new_block, name)
        parse(remaining, updated_block, new_results)
    end
  end
  def parse(<<_char :: size(8), rest :: binary>>, block, results), do: parse(rest, block, results)

  @doc """
  Collects all non-terminal characters following a clause match in `parse/3`

  Returns the binary part following the directive match plus any number of spaces up to a terminating character

  ## Examples

    iex> MrRoboto.Parser.get_value "", "value #comment"
    "value"

    iex> MrRoboto.Parser.get_value "", " value\n"
    "value"

    iex> MrRoboto.Parser.get_value "", "value other stuff"
    "value"

  """
  def get_value(value, contents)
  def get_value("", <<" ", rest :: binary>>), do: get_value("", rest)
  def get_value(name, <<"#", rest :: binary>>), do: {name, "#" <> rest}
  def get_value(name, <<" ", rest :: binary>>), do: {name, rest}
  def get_value(name, <<"\n", rest :: binary>>), do: {name, rest}
  def get_value(name, <<"\r\n", rest :: binary>>), do: {name, rest}
  def get_value(name, <<char :: size(8), rest :: binary>>) do
    get_value name <> IO.chardata_to_string([char]), rest
  end

  @doc """
  Consumes all characters until \n or \r\n is seen

  Returns the rest of the binary

  ## Examples

    iex> MrRoboto.Parser.consume_comment "the body of a comment\nUser-agent: *"
    "User-agent: *"
  """
  def consume_comment(<<"\n", rest :: binary>>), do: rest
  def consume_comment(<<"\r\n", rest :: binary>>), do: rest
  def consume_comment(<<_char :: size(8), rest :: binary>>), do: consume_comment(rest)

  @doc """
  Adds a user-agent value to the current `block` map

  Returns a `block` map

  ## Examples

    iex> MrRoboto.Parser.add_agent MrRoboto.Parser.new_block, "*"
    %{user_agents: ["*"], allow: [], disallow: [], delay: nil}

    iex> MrRoboto.Parser.add_agent %{user_agents: ["*"], allow: [], disallow: [], delay: nil}, "google-news"
    %{user_agents: ["google-news", "*"], allow: [], disallow: [], delay: nil}

  """
  def add_agent(block, name) do
    Map.update(block, :user_agents, [name], fn current ->
      [name] ++ current
    end)
  end

  @doc """
  Adds an allow expression to the current `block` map

  Returns a `block` map

  ## Examples

    iex> MrRoboto.Parser.add_allow MrRoboto.Parser.new_block, "/"
    %{user_agents: [], allow: ["/"], disallow: [], delay: nil}

    iex> MrRoboto.Parser.add_allow %{user_agents: [], allow: ["/"], disallow: [], delay: nil}, "/foo/"
    %{user_agents: [], allow: ["/foo/", "/"], disallow: [], delay: nil}

  """
  def add_allow(block, name) do
    Map.update(block, :allow, [name], fn current ->
      [name] ++ current
    end)
  end

  @doc """
  Adds a disallow expression to the current `block` map

  Returns a `block` map

  ## Examples

    iex> MrRoboto.Parser.add_disallow MrRoboto.Parser.new_block, "/"
    %{user_agents: [], allow: [], disallow: ["/"], delay: nil}

    iex> MrRoboto.Parser.add_disallow %{user_agents: [], allow: [], disallow: ["/"], delay: nil}, "/foo/"
    %{user_agents: [], allow: [], disallow: ["/foo/", "/"], delay: nil}
  """
  def add_disallow(block, path) do
    Map.update(block, :disallow, [path], fn current ->
      [path] ++ current
    end)
  end

  @doc """
  Builds `MrRoboto.Rules` structs for each user-agent in the block

  Returns a list of `MrRoboto.Rules` structs

  ## Examples

    iex> block = %{user_agents: ["*"], allow: ["/"], disallow: ["/foo/"], delay: nil}
    iex> MrRoboto.Parser.build_rules block
    [%MrRoboto.Rules{user_agent: "*", allow: ["/"], disallow: ["/foo/"], crawl_dealy: 1000}]

    iex> block = %{user_agents: ["google-news", "*"], allow: ["/"], disallow: ["/foo/"], delay: nil}
    iex> MrRoboto.Parser.build_rules block
    [%MrRoboto.Rules{user_agent: "*", allow: ["/"], disallow:["/foo/"], crawl_delay: 1000}, %MrRoboto.Parser{user_agent: "google-news", allow: ["/"], disallow: ["/foo/"], crawl_dealy: 1000}]

  """
  def build_rules(block) do
    Enum.map(block[:user_agents], fn agent ->
      %Rules{user_agent: agent, allow: block.allow, disallow: block.disallow}
    end)
  end

  @doc """
  Creates a new `block` representation for the parser

  Returns a clean `block` map

  ## Examples

    iex> MrRoboto.Parser.new_block
    %{user_agents: [], allow: [], disallow: [], delay: nil}

  """
  def new_block do
    %{user_agents: [], allow: [], disallow: [], delay: nil}
  end
end
