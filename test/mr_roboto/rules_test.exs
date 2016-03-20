defmodule MrRoboto.RulesTest do
  use ExUnit.Case, async: true

  alias MrRoboto.Rules

  @rules %Rules{}
  @delay 2000

  test "set_delay sets the crawl_delay for the rule set" do
    assert @delay = Rules.set_delay(@rules, @delay).crawl_delay
  end

  test "it indicates a forward match direction if the directive doesn't end in '$'" do
    assert :forwards = Rules.match_direction "/foo/"
  end

  test "it indicates a backwards match direction if the directive ends in '$'" do
    assert :backwards = Rules.match_direction "/*.php$"
  end

  test "it correctly indicates if a regular directive applies" do
    assert Rules.directive_applies? "/foo", "/foo/bar/page"
  end

  test "it correctly indicates if a wildcarded directive applies" do
    assert Rules.directive_applies? "/foo*s", "/foo/bar/pages"
  end

  test "it correctly indicates if a regular directive does not apply" do
    refute Rules.directive_applies? "/foo/", "/foo"
  end

  test "it correctly indicates if a wildcarded directive does not apply" do
    refute Rules.directive_applies? "/f*s", "/fido/"
  end
end
