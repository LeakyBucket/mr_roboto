defmodule MrRoboto.Agent do
  use GenServer

  @default_expiration 21600

  def start_link do
    HTTPoison.start

    GenServer.start_link(__MODULE__, %{})
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
