defmodule MrRoboto.Parser do
  alias MrRoboto.Rules

  #parse takes the binary, a map for the current block and an accumulator for blocks
  def start_parse(body) do
    parse body, new_block, []
  end

  def parse("", block, results), do: build_rules(block) ++ results
  def parse(<<"#", rest :: binary>>, block, results), do: parse(consume_comment(rest), block, results)
  def parse(<<"allow:", rest :: binary>>, block, results) do
    {remaining, updated_block} = allow("", rest, block)
    parse(remaining, updated_block, results)
  end
  def parse(<<"user-agent:", rest :: binary>>, block, results) do
    case block do
      %{user_agents: _agents, allow: [], disallow: [], delay: nil} ->
        {remaining, updated_block} = user_agent("", rest, block)
        parse(remaining, updated_block, results)
      _ ->
        new_results = build_rules(block) ++ results
        {remaining, block} = user_agent("", rest, new_block)
        parse(remaining, block, new_results)
    end
  end

  def user_agent("", <<" ", rest :: binary>>, block), do: user_agent("", rest, block)
  def user_agent(name, <<"#", rest :: binary>>, block), do: {"#" <> rest, add_agent(block, name)}
  def user_agent(name, <<" ", rest :: binary>>, block), do: {rest, add_agent(block, name)}
  def user_agent(name, <<"\n", rest :: binary>>, block), do: {rest, add_agent(block, name)}
  def user_agent(name, <<char :: size(8), rest :: binary>>, block) do
    user_agent name <> IO.chardata_to_string([char]), rest, block
  end

  def allow("", <<" ", rest :: binary>>, block), do: allow("", rest, block)
  def allow(name, <<"#", rest :: binary>>, block), do: {"#" <> rest, add_allow(block, name)}
  def allow(name, <<" ", rest :: binary>>, block), do: {rest, add_allow(block, name)}
  def allow(name, <<"\n", rest :: binary>>, block), do: {rest, add_allow(block, name)}
  def allow(name, <<char :: size(8), rest :: binary>>, block) do
    allow name <> IO.chardata_to_string([char]), rest, block
  end

  def consume_comment(<<"\n", rest :: binary>>), do: rest
  def consume_comment(<<"\r\n", rest :: binary>>), do: rest
  def consume_comment(<<_char :: size(8), rest :: binary>>), do: consume_comment(rest)

  def add_agent(block, name) do
    Map.update(block, :user_agents, [name], fn current ->
      [name] ++ current
    end)
  end

  def add_allow(block, name) do
    Map.update(block, :allow, [name], fn current ->
      [name] ++ current
    end)
  end

  def build_rules(block) do
    Enum.map(block[:user_agents], fn agent ->
      %Rules{user_agent: agent, allow: block.allow, disallow: block.disallow}
    end)
  end

  def new_block do
    %{user_agents: [], allow: [], disallow: [], delay: nil}
  end
end
