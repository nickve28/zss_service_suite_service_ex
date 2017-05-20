use Mix.Config

config :logger,
  backends: []

config :zss_service,
  socket_adapter: ZssService.Mocks.Adapters.Socket,
  service_supervisor: ZssService.Mocks.ServiceSupervisor