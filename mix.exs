defmodule GracefulStop.MixProject do
  use Mix.Project

  def project do
    [
      app: :graceful_stop,
      version: "0.1.0",
      elixir: "~> 1.6",
      description: description(),
      package: package(),
      source_url: "https://github.com/botsqd/graceful_stop",
      homepage_url: "https://github.com/botsqd/graceful_stop",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp description do
    "Gracefully stop the system after running shutdown hooks. Also catches SIGTERM."
  end

  defp package do
    %{
      files: ["lib", "mix.exs", "*.md", "LICENSE"],
      maintainers: ["Arjan Scherpenisse"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/botsqd/match_engine"}
    }
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {GracefulStop.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
