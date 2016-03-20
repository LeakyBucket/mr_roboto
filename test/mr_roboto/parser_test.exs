defmodule MrRoboto.ParserTest do
  use ExUnit.Case, async: true
  doctest MrRoboto.Parser

  alias MrRoboto.Parser
  alias MrRoboto.Rules

  @single_agent Path.expand(".") <> "/test/support/single_agent.txt"
  @double_agent Path.expand(".") <> "/test/support/double_agent.txt"
  @buddy_agents Path.expand(".") <> "/test/support/buddy_agents.txt"

  test "it builds a single record for a file with one 'User-agent'" do
    {:ok, content} = File.read @single_agent

    assert [%Rules{}] = Parser.start_parse content
  end

  test "it builds two rules for a file with two separate 'User-agent' blocks" do
    {:ok, content} = File.read @double_agent

    assert [%Rules{}, %Rules{}] = Parser.start_parse content
  end

  test "it builds two rules for a file with two 'User-agent' declarations sharing a block" do
    {:ok, content} = File.read @buddy_agents

    assert [%Rules{}, %Rules{}] = Parser.start_parse content
  end

  test "consume_comment processes up to '\\n'" do
    data = "#comment\nuser-agent: MrRoboto"

    assert "user-agent: MrRoboto" = Parser.consume_comment data
  end

  test "consume_comment processes up to '\\r\\n'" do
    data = "#comment\r\nuser-agent: MrRoboto"

    assert "user-agent: MrRoboto" = Parser.consume_comment data
  end

  test "it reads a '\\n' terminated value" do
    data = "/\n"

    assert {"/", ""} = Parser.get_value("", data)
  end

  test "it reads a comment terminated value" do
    data = "/#touchy feely comment"

    assert {"/", "#touchy feely comment"} = Parser.get_value("", data)
  end

  test "it consumes the value when terminated with a space" do
    data = "/ some other crap"

    assert {"/", "some other crap"} = Parser.get_value("", data)
  end

  test "it consumes the value when preceeded with a space" do
    data = " /\n"

    assert {"/", ""} = Parser.get_value("", data)
  end

  test "build_rules creates a rule for each user-agent in the block" do
    rules = Parser.build_rules %{user_agents: ["google-news", "google"], allow: ["/"], disallow: []}

    assert 2 = Enum.count(rules)
  end

  test "build_rules correctly populates a rule" do
    rule = Parser.build_rules %{user_agents: ["google-news"], allow: ["/"], disallow: []}

    assert [%Rules{user_agent: "google-news", allow: ["/"], disallow: [], crawl_delay: 1000}] = rule
  end

  test "add_agent adds a user agent to the block map" do
    assert %{user_agents: ["google-news", "google"]} = Parser.add_agent(%{user_agents: ["google"]}, "google-news")
  end

  test "it adds an initial allow entry to the block map" do
    assert %{allow: ["/"]} = Parser.add_allow(%{}, "/")
  end

  test "it adds an additional allow entry to the block map" do
    assert %{allow: ["/foo", "/"]} = Parser.add_allow(%{allow: ["/"]}, "/foo")
  end

  test "it adds an initial disallow value to the block map" do
    assert %{disallow: ["/foo"]} = Parser.add_disallow(%{}, "/foo")
  end

  test "it adds an additional disallow value to the block map" do
    assert %{disallow: ["/foo", "/bar"]} = Parser.add_disallow(%{disallow: ["/bar"]}, "/foo")
  end
end
