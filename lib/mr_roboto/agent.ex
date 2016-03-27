defmodule MrRoboto.Agent do
  @moduledoc """
  The Agent fetches the `robots.txt` file from a given site.

  The agent is a very simple `GenServer` with the sole purpose of requesting the `robots.txt` file from a site.

  The agent responds to a single call `{:check, site}` where site is the URL of the site from which `robots.txt` should be fetched.

  The `:check` call returns one of three general responses:

  * `{:ok, body}`
  * `{:ok, :current}`
  * `{:error, error}`

  The Agent will only request the `robots.txt` file if it was last requested more than `MrRoboto.Agent.default_expiration` seconds ago.
  If the Agent receives a request for a robots file and it has been requested inside the cache window it responds with `{:ok, :current}`, otherwise it responds with `{:ok, body}`

  In the event of an error the Agent will return `{:error, error}` where `error` is the `HTTPoison` error.
  """

  use GenServer

  @default_expiration 21600

  def start_link do
    HTTPoison.start

    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def handle_call({:check, site}, _from, state) do
    case update_robot(site, state) do
      {:ok, decision, new_history} ->
        {:reply, {:ok, decision}, new_history}
      {:error, error, state} ->
        {:reply, {:error, error}, state}
    end
  end

  def default_expiration do
    @default_expiration
  end

  def update_robot(site, history) do
    case Map.fetch(history, site) do
      {:ok, fetched_at} ->
        if (fetched_at + @default_expiration) > :erlang.system_time(:seconds) do
          {:ok, :current, history}
        else
          fetch_robots(site, history)
        end
      :error ->
        fetch_robots(site, history)
    end
  end

  def fetch_robots(site, history) do
    case HTTPoison.get(site <> "/robots.txt") do
      {:ok, response} ->
        {:ok, response.body, update_timestamp(site, history)}
      {:error, reason} ->
        {:error, reason, history}
    end
  end

  def update_timestamp(site, history) do
    Map.put(history, site, :erlang.system_time(:seconds))
  end
end
