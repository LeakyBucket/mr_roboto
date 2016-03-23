defmodule MrRoboto.RulesTest do
  use ExUnit.Case, async: true

  alias MrRoboto.Rules

  @directives ["/foo", "/hello/world/foo/bar", "/hello/world", "/foo/bar/world", "/*.php$"]
  @disallows ["/hello", "/*world$"]
  @allows ["/foo", "/*php$", "/foo*bar"]
  @delay 2000

  @rule %Rules{user_agent: "*", allow: @allows, disallow: @disallows}

  test "set_delay sets the crawl_delay for the rule set" do
    assert @delay = Rules.set_delay(@rule, @delay).crawl_delay
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

  test "it correctly indicates if an end of path directive does not apply" do
    refute Rules.directive_applies? "/index.html$", "/hello/index.json"
  end

  test "it returns \"\" when there was no matching directive" do
    assert "" = Rules.longest_match @directives, "/uncle/sam", ""
  end

  test "it returns the matching directive when there is only one" do
    assert "/foo" = Rules.longest_match @directives, "/foo/world", ""
  end

  test "it returns the longest when multiple directives match" do
    assert "/hello/world/foo/bar" = Rules.longest_match @directives, "/hello/world/foo/bar/baz.html", ""
  end

  test "it returns the longest when an end of path directive matches" do
    assert "/*.php$" = Rules.longest_match @directives, "/uncle/bob.php", ""
  end

  test "it returns true if the path is permitted under the given rule" do
    assert Rules.permitted? @rule, "/foo/bar/baz.php"
  end

  test "it returns false if the path is not permitted under the given rule" do
    refute Rules.permitted? @rule, "/this/is/our/world"
  end

  test "it indicates if the permission is ambiguous under the given rule" do
    assert :ambiguous = Rules.permitted? @rule, "/hello.php"
  end
end
