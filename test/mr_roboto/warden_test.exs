defmodule MrRoboto.WardenTest do
  use ExUnit.Case, async: true

  alias MrRoboto.Agent
  alias MrRoboto.Rules
  alias MrRoboto.Warden

  @records %{
    "www.google.com" => %{
      "*" => %Warden{rule: %Rules{user_agent: "*", allow: ["/foo"], disallow: ["/bar"]}, last_applied: nil}
    },
    "www.lawlytics.com" => %{
      "*" => %Warden{rule: %Rules{user_agent: "*", allow: ["/foo"], disallow: ["/bar"]}, last_applied: nil},
      "google" => %Warden{rule: %Rules{user_agent: "google", allow: ["/foo"], disallow: ["/bar"]}, last_applied: nil}
    }
  }

  test "the server indicates if a path can be crawled" do
    assert :allowed = GenServer.call Warden, {:crawl?, {"mybot", "https://www.google.com/search/about"}}
  end

  test "the server indicates that a path can not be crawled" do
    assert :disallowed = GenServer.call Warden, {:crawl?, {"mybot", "https://www.google.com/search"}}
  end

  test "it doesn't update the records if the 'robots.txt' is current" do
    GenServer.call Agent, {:check, "www.yahoo.com"}

    assert @records = Warden.update_records "www.yahoo.com", @records
  end

  test "it updates the records if the 'robots.txt' file is not current" do
    updated = Warden.update_records "www.bing.com", @records

    assert Map.has_key? updated, "www.bing.com"
  end

  test "it doesn't update the records if there was an error" do
    assert @records = Warden.update_records "uncle", @records
  end

  test "it allows a check if the rule allows" do
    rule = %Rules{user_agent: "*", allow: ["/"], disallow: []}
    warden_record = %Warden{rule: rule, last_applied: :erlang.system_time(:seconds) - 3000}

    assert Warden.permitted?(warden_record, "/")
  end

  test "it disallows a check if the rule indicates it is not allowed" do
    rule = %Rules{user_agent: "*", allow: [], disallow: ["/"]}
    warden_record = %Warden{rule: rule}

    refute Warden.permitted?(warden_record, "/")
  end

  test "it indicates if the outcome is ambiguous" do
    rule = %Rules{user_agent: "*", allow: ["/"], disallow: ["/"]}
    warden_record = %Warden{rule: rule}

    assert :ambiguous = Warden.permitted?(warden_record, "/")
  end
end
