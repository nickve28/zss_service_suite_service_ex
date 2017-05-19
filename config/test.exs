use Mix.Config

config :logger,
  compile_time_purge_level: :error

config :zss_service,
  socket_adapter: ZssService.Mocks.Adapters.Socket