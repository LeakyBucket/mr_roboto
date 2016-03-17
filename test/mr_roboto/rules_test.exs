defmodule MrRoboto.RulesTest do
  use ExUnit.Case, async: true

  alias MrRoboto.Rules

  @agent "MrRoboto"
  @root "/"
  @first_level "/first/"
  @second_level "/first/second/"
  @delay 2000

  @rules %Rules{}

  test "allow adds a path to the allowed list" do
    assert [@second_level] = Rules.allow(@rules, @second_level).allow
  end

  test "disallow adds a path to the disallowed list" do
    assert [@first_level] = Rules.disallow(@rules, @first_level).disallow
  end

  test "agent sets the user_agent for the rule set" do
    assert @agent = Rules.agent(@rules, @agent).user_agent
  end

  test "set_delay sets the crawl_delay for the rule set" do
    assert @delay = Rules.set_delay(@rules, @delay).crawl_delay
  end
end
