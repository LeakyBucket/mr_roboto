defmodule MrRoboto.ParserTest do
  use ExUnit.Case, async: true

  alias MrRoboto.Parser
  alias MrRoboto.Rules

  @single_agent """
  User-agent: *
  Allow: /
  """

  test "parse returns a single record for one user-agent" do
    expected = [%Rules{user_agent: "*", allow: ["/"], disallow: [], crawl_delay: 1000}]

    assert ^expected = Parser.start_parse @single_agent
  end

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

  test "add_allow adds an allow entry to the block map" do
    assert %{allow: ["/"]} = Parser.add_allow(%{}, "/")
  end
end
