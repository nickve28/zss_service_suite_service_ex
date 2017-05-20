Code.require_file("./test/mocks/adapters/socket.ex")
Code.require_file("./test/mocks/test_sender.ex")
Code.require_file("./test/mocks/service_supervisor.ex")

ZssService.Mocks.Adapters.Socket.start

ExUnit.start()