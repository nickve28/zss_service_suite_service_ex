defmodule ZssService.Mocks.ServiceSupervisor do
  def start_child(_sup, {_module, _fun, [_socket, _config]}) do
    :ok
  end
end