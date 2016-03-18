defmodule MrRoboto.ParserTest do
  use ExUnit.Case, async: true

  alias MrRoboto.Parser
  alias MrRoboto.Rules

  test "consume_comment processes up to '\\n'" do
    data = "#comment\nuser-agent: MrRoboto"

    assert "user-agent: MrRoboto" = Parser.consume_comment data
  end

  test "consume_comment processes up to '\\r\\n'" do
    data = "#comment\r\nuser-agent: MrRoboto"

    assert "user-agent: MrRoboto" = Parser.consume_comment data
  end

  test "user_agent adds a user-agent to the block when '\\n' terminated" do
    data = "google-news\n"

    assert {"", %{user_agents: ["google-news"]}} = Parser.user_agent("", data, %{})
  end

  test "user_agent adds a user-agent when terminated with a comment" do
    data = "google-news#touchy feely comment"

    assert {"#touchy feely comment", %{user_agents: ["google-news"]}} = Parser.user_agent("", data, %{})
  end

  test "user_agent adds a user-agent to the block when ' ' terminated" do
    data = "google-news some other crap"

    assert {"some other crap", %{user_agents: ["google-news"]}} = Parser.user_agent("", data, %{})
  end

  test "user_agent adds a user-agent to the block when there is a leading ' '" do
    data = " google-news\n"

    assert {"", %{user_agents: ["google-news"]}} = Parser.user_agent("", data, %{})
  end

  test "allow adds an allow entry to the block when '\\n' terminated" do
    data = "/\n"

    assert {"", %{allow: ["/"]}} = Parser.allow("", data, %{})
  end

  test "allow adds an allow entry when terminated with a comment" do
    data = "/#touchy feely comment"

    assert {"#touchy feely comment", %{allow: ["/"]}} = Parser.allow("", data, %{})
  end

  test "allow adds an allow entry to the block when ' ' terminated" do
    data = "/ some other crap"

    assert {"some other crap", %{allow: ["/"]}} = Parser.allow("", data, %{})
  end

  test "allow adds an allow entry when there is a ' ' before the entry" do
    data = " /\n"

    assert {"", %{allow: ["/"]}} = Parser.allow("", data, %{})
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

  test "add_allow adds an allow entry to the block map" do
    assert %{allow: ["/"]} = Parser.add_allow(%{}, "/")
  end
end
