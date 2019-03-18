defmodule Scrappy.MixProject do
  use Mix.Project

  def project do
    [
      app: :scrappy,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:flow, "~> 0.14"},
      {:httpoison, "~> 1.5"},
      {:progress_bar, "> 0.0.0"}
    ]
  end
end
