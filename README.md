# MrRoboto

[![Coverage Status](https://coveralls.io/repos/github/LeakyBucket/mr_roboto/badge.svg?branch=master)](https://coveralls.io/github/LeakyBucket/mr_roboto?branch=master)
[![Build](https://travis-ci.org/LeakyBucket/mr_roboto.svg?branch=master)]

A simple `robots.txt` service.  MrRoboto will fetch and parse `robots.txt` files for you and indicate whether a path is crawlable by your user agent.  It also has primitive support for the `Crawl-dealy` directive.

## Installation

[Available in Hex](https://hex.pm/packages/mr_roboto/1.0.0), the package can be installed as:

  1. Add mr_roboto to your list of dependencies in `mix.exs`:

        def deps do
          [{:mr_roboto, "~> 1.0.0"}]
        end

  2. Ensure mr_roboto is started before your application:

        def application do
          [applications: [:mr_roboto]]
        end

## Usage

### Checking a URL

Checking a URL is simple, just send `{:crawl?, {agent, url}}` to the `Warden` server.

```
GenServer.call MrRoboto.Warden, {:crawl?, {"mybot", "http://www.google.com"}}
```

The `Warden` server will reply with `:allowed`, `:disallowed` or `:ambiguous`.

In the case of an `:ambiguous` response it is up to your discression how to proceed.  The `:ambiguous` response indicates that there were matching __allow__ and __disallow__ directives of the same length.

### Crawl Delay

`Crawl-delay` isn't a very common directive but `MrRoboto` attempts to support it.  The `Warden` server supports a `delay_info` call which will return the delay value and when the rule was last checked.

```
iex> GenServer.call MrRoboto.Warden, {:delay_info, {"mybog", "http://www.google.com"}}
%{delay: 1, last_checked: 1459425496}
```
