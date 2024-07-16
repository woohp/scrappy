defmodule Scrappy.MixProject do
  use Mix.Project

  def project do
    [
      app: :scrappy,
      version: "0.2.0",
      elixir: "~> 1.17",
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
      {:flow, "~> 1.2"},
      {:httpoison, "~> 2.2"},
      {:progress_bar, "> 0.0.0"}
    ]
  end
end
