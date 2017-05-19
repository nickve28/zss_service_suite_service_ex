use Mix.Config

config :logger,
  backends: [:console],
  compile_time_purge_level: :info

config :zss_service,
  socket_adapter: ZssService.Adapters.Socket