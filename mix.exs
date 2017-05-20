defmodule ZssService.Mixfile do
  use Mix.Project

  def project do
    [app: :zss_service,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [
      extra_applications: [:logger, :czmq, :uuid, :msgpax],
      mod: {ZssService, []}
    ]
  end

  defp deps do
    [
      {:czmq, github: "gar1t/erlang-czmq", compile: "LDFLAGS=-lrt ./configure; make"},
      {:msgpax, "~> 1.0"},
      {:uuid, "~> 1.1"}
    ]
  end
end
