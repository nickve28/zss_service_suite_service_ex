defmodule ZssService.Mixfile do
  use Mix.Project

  @version "0.2.0"

  def project do
    [app: :zss_service,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  #Ideally we'd rely on application inference supported since 1.4
  #But since we want to support <1.4, we rely on the older mechanism
  @applications [:logger, :uuid, :msgpax, :chumak]

  def application do
    [
      applications: @applications,
      mod: {ZssService, []}
    ]
  end

  defp deps do
    [
      {:chumak, "~> 1.2"},
      {:msgpax, "~> 1.0"},
      {:uuid, "~> 1.1"},
      {:credo, "~> 0.3", only: [:dev, :test]}
    ]
  end
end
