defmodule GracefulStop.MixProject do
  use Mix.Project

  @source_url "https://github.com/botsquad/graceful_stop"
  @version File.read!("VERSION")

  def project do
    [
      app: :graceful_stop,
      version: @version,
      elixir: "~> 1.11",
      description: description(),
      package: package(),
      source_url: @source_url,
      homepage_url: @source_url,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp description do
    "Gracefully stop the system after running shutdown hooks. Also catches SIGTERM."
  end

  defp package do
    %{
      files: ["lib", "mix.exs", "*.md", "LICENSE", "VERSION"],
      maintainers: ["Arjan Scherpenisse"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/botsquad/graceful_stop"}
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
