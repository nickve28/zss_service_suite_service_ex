Code.require_file("./test/mocks/adapters/socket.ex")
Code.require_file("./test/mocks/test_sender.ex")
Code.require_file("./test/mocks/datetime.ex")
Code.require_file("./test/mocks/service_supervisor.ex")

Code.require_file("./test/mocks/broker.ex")

ZssService.Mocks.Adapters.Socket.start
ZssService.Mocks.ServiceSupervisor.start
ZssService.Mocks.DateTime.start

ExUnit.start()
