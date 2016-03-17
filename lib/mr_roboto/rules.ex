defmodule MrRoboto.Rules do
  defstruct user_agent: '', allow: [], disallow: [], crawl_delay: 1000

  def agent(rule, name) do
    struct(rule, user_agent: name)
  end

  def allow(rule, path) do
    struct(rule, allow: [path] ++ rule.allow)
  end

  def disallow(rule, path) do
    struct(rule, disallow: [path] ++ rule.disallow)
  end

  def set_delay(rule, frequency) do
    struct(rule, crawl_delay: frequency)
  end
end
