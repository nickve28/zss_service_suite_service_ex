defmodule ZssService.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :zss_service,
      version: @version,
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/nickve28/zss_service_suite_service_ex"
    ]
  end

  #Ideally we'd rely on application inference supported since 1.4
  #But since we want to support <1.4, we rely on the older mechanism
  @applications [:logger, :czmq, :uuid, :msgpax]

  def application do
    [
      applications: @applications,
      mod: {ZssService, []}
    ]
  end

  defp description do
    """
    A service worker to connect with the ZeroMQ ZSS Service Broker.
    """
  end

  defp package do
    [
      name: :zss_service,
      maintainers: ["Nick van Eijk"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nickve28/zss_service_suite_service_ex"}
    ]
  end

  defp deps do
    [
      {:czmq, github: "gar1t/erlang-czmq", compile: "LDFLAGS=-lrt ./configure; make"},
      {:msgpax, "~> 1.0"},
      {:uuid, "~> 1.1"},
      {:credo, "~> 0.3", only: [:dev, :test]}
    ]
  end
end
