defmodule MrRoboto.AgentTest do
  use ExUnit.Case, async: true

  alias MrRoboto.Agent

  @checked "https://www.google.com"
  @history %{@checked => :erlang.system_time(:seconds)}

  test "start_link starts the server" do
    assert {:ok, _pid} = start_agent
  end

  test "handle_call {:check, site} returns the robot body if the site is new" do
    {:ok, agent} = start_agent

    assert {:ok, body} = GenServer.call agent, {:check, "https://www.google.com"}
    assert is_binary(body)
  end

  test "handle_call {:check, site} indicates if robot check is current" do
    {:ok, agent} = start_agent
    GenServer.call agent, {:check, "https://www.lawlytics.com"}

    assert {:ok, :current} = GenServer.call agent, {:check, "https://www.lawlytics.com"}
  end

  test "handle_call {:check, site} indicates if there was an error retrieving the file" do
    {:ok, agent} = start_agent

    assert {:error, _reason} = GenServer.call agent, {:check, "http://lvh.me"}
  end

  test "update_robot indicates if the robots file has been fetched and is current" do
    assert {:ok, :current, _} = Agent.update_robot(@checked, @history)
  end

  test "update_robot fetches the robots.txt file if it has never been retrieved" do
    {:ok, robots_body, _} = Agent.update_robot("https://www.lawlytics.com", @history)

    assert is_binary(robots_body)
  end

  test "update_robot fetches the robots.txt file if the last check is too old" do
    long_ago = :erlang.system_time(:seconds) - (Agent.default_expiration + 1)
    old_check = %{@checked => long_ago}

    {:ok, robots_body, _} = Agent.update_robot(@checked, old_check)

    assert is_binary(robots_body)
  end

  test "fetch_robots retrieves the robots.txt file for the given site" do
    assert {:ok, response, _} = Agent.fetch_robots("https://www.lawlytics.com", @history)
    assert is_binary(response)
  end

  test "update_timestamp updates the check time for the site" do
    the_past = :erlang.system_time(:seconds) - 30
    %{"https://www.google.com" => nowish} = Agent.update_timestamp(@checked, %{"https://www.google.com" => the_past})

    assert nowish > the_past
  end

  test "update_timestamp enters a timestamp if there isn't one already" do
    new_history = Agent.update_timestamp("https://www.lawlytics.com", @history)

    assert Map.get(new_history, "https://www.lawlytics.com")
  end

  def start_agent do
    Agent.start_link
  end
end
