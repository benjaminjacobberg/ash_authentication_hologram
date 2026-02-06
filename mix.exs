defmodule AshAuthenticationHologram.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/benjaminjacobberg/ash_authentication_hologram"

  def project do
    [
      app: :ash_authentication_hologram,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      name: "AshAuthenticationHologram",
      description: "Hologram integration for AshAuthentication.",
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:hologram, "~> 0.6.6"},
      {:ash_authentication, "~> 4.0"},
      {:phoenix, "~> 1.7"},
      {:plug, "~> 1.14"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "AshAuthentication.Hologram",
      source_ref: "v#{@version}",
      extras: ["README.md"]
    ]
  end
end
