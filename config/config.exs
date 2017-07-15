use Mix.Config

config :logger,
  backends: [:console],
  compile_time_purge_level: :info

config :zss_service,
  socket_adapter: ZssService.Adapters.Socket,
  service_supervisor: ZssService.ServiceSupervisor,
  datetime_module: DateTime

if Mix.env == :test do
  import_config "test.exs"
end
