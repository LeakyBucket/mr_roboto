defmodule MrRoboto.Mixfile do
  use Mix.Project

  def project do
    [app: :mr_roboto,
     version: "1.0.0",
     elixir: "~> 1.2",
     name: "Mr. Roboto",
     description: "A simple robots.txt service",
     source_url: "https://github.com/LeakyBucket/mr_roboto",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: Coverex.Task, coveralls: true],
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {MrRoboto, []},
     applications: [:logger, :httpoison]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:httpoison, "~> 0.8.0"},
     {:credo, "~> 0.3", only: [:dev, :test]},
     {:coverex, "~> 1.4.8", only: :test},
     {:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev}]
  end

  defp description do
    """
    A simple robots.txt service.
    """
  end

  defp package do
    [
     maintainers: ["Glen Holcomb"],
     licenses: ["MIT"],
    ]
  end
end
