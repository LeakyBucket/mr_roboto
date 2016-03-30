defmodule MrRoboto.Warden do
  @moduledoc """
  The Warden is responsible for coordinating the retrieval, parsing and checking
  of `robots.txt` files.

  It maintains a map of hosts checked and the rules for those hosts.  When asked
  it will retrieve the rule in question and check to see if the specified
  `user-agent` is allowed to crawl that path.
  """

  use GenServer

  alias MrRoboto.Agent
  alias MrRoboto.Parser
  alias MrRoboto.Rules

  defstruct rule: nil, last_check: 0

  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def handle_call({:crawl?, {agent, url}}, _from, state) do
    uri = URI.parse(url)
    updated_records = update_records(uri.host, state)

    agent
    |> fetch_record(uri.host, updated_records)
    |> permitted?(uri.path)
    |> case do
      true ->
        {:reply, :allowed, updated_records}
      false ->
        {:reply, :disallowed, updated_records}
      :ambiguous ->
        {:reply, :ambiguous, updated_records}
    end
  end

  def handle_cast({:set_check, url, agent}, state) do
    new_state = update_in state, [URI.parse(url).host, agent, :last_check], :erlang.system_time(:seconds)

    {:noreply, new_state}
  end

  defp fetch_record(user_agent, host, records) do
    records
    |> get_in([host, user_agent])
    |> case do
      %__MODULE__{} = found ->
        found
      _ ->
        get_in records, [host, "*"]
    end
  end

  @doc """
  Updates the state for the Warden.

  Returns a nested map of Warden structs.

  If the `robots.txt` data is stale or it has not been fetched yet it returns a
  new nested map of Warden structs.  In the event of an `:error` or the data
  being current it returns the current records map.

  ## Examples

    _update_records_ is responsible for managing the state for the Warden server.
    This state is a collection of `MrRoboto.Warden.t` structs indexed by host
    and user-agent, where there is __one__ `MrRoboto.Warden.t` struct per
    _user-agent_ and potentially many _user-agents_ per _host_.

    ```
      %{
        "google.com" => %{
          "*" => %{rule: %MrRoboto.Rules{}, last_check: time_in_seconds},
        }
      }
    ```

  """
  def update_records(host, records) do
    Agent
    |> GenServer.call({:check, host})
    |> case do
      {:ok, :current} ->
        records
      {:ok, body} ->
        body
        |> Parser.start_parse
        |> insert(records, host)
      {:error, _reason} ->
        records
    end
  end

  defp insert(rule_set, current_records, host) do
    rules = Enum.into(rule_set, %{}, fn rule ->
      {rule.user_agent, %__MODULE__{rule: rule}}
    end)

    Map.put current_records, host, rules
  end

  @doc """
  Indicates whether the given path can be crawled

  Retrns `true`, `false` or `:ambiguous`

  The `Warden` takes two factors into consideration when determining whether a
  path is legal.  The first factor are the directives in `robots.txt` for the
  user-agent.  The second is the last time a check was recorded for the site.

  ## Examples

    If the rule indicates that the path is legal then the `last_check` time is
    compared to the current time before returning an answer.

    ```
    iex> Warden.permitted? %Warden{rule: %Rules{user_agent: "*", allow: ["/"], disallow: [], crawl_delay: 1000}, last_check: 0}, "/"
    # assuming the current time is large enough
    true
    # assuming the current time is say 5
    false
    ```

    In the case where the `MrRoboto.Rules` struct indicates that the rule is
    not permitted then `false` is returned.

    __Note__: The `last_check` is not considered in this case

    ```
    iex> Warden.permitted? %Warden{rule: %Rules{user_agent: "*", allow: [], disallow: ["/"]}}, "/"
    false
    ```

    In the case where the `MrRoboto.Rules` struct is ambiguous as to permission
    then `:ambiguous` is returned.

    __Note__: The `last_check` is not considered in this case

    ```
    iex> Warden.permitted? %Warden{rule: %Rules{user_agent: "*", allow: ["/"], disallow: ["/"]}}, "/"
    ```

  """
  def permitted?(%__MODULE__{rule: rule, last_check: last_check}, path) do
    Rules.permitted?(rule, path || "/")
  end
end
