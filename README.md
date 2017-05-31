# ZSS ZeroMQ Service

[![Build Status](https://travis-ci.org/nickve28/zss_service_suite_service_ex.svg?branch=master)](https://travis-ci.org/nickve28/zss_service_suite_service_ex)

**Warning: NOT PRODUCTION READY**

## Purpose

This is an Elixir implementation of a service worker for the [Micro Toolkit ZSS Broker](https://github.com/micro-toolkit/zmq-service-suite-broker-js). This is not an official repo.

It allows connecting your Elixir application to an existing NodeJS project using the Broker and its associated clients/workers.

## When to use this

In order to use ZeroMQ with erlang, you have 3 options.

1. Use one of the libraries that connect to ZeroMQ using Erlang NIF. This is risky because using NIFs, you can no longer guarantee the fault tolerance the Beam VM provides you with.
2. Use a port that acts as an intermediate between the ZeroMQ czmq libraries and Erlang. The consequence is you need to poll the messages into Erlang/Elixir. This can cause a slight increase in latency.
3. Use a full Erlang based ZMQ implementation.

The second option has been chosen for this project, the slight increase in latency is worth the tradeoff compared to losing the reliabily of the Beam VM.

This library is intended for use when you want to add an Elixir/Erlang based service into your existing ZSS stack using the official Ruby/NodeJS clients and workers.


## Installation

T.B.D.

## Creating a Service Worker

In order to create service workers, you start by creating a configuration struct. This could look like the following.

```elixir
config = ZssService.get_instance %{sid: "PING", broker: "tcp://127.0.0.1:7776", timeout: 1500}
```

broker and timeout are optional properties and will default to "tcp://127.0.0.1:7776" and 1000 respectively.

After creating the configuration, you can add verbs/routes the following way

```elixir
config = ZssService.add_verb(config, {"LIST", MyModule, :my_fun})
```

Chaining the previous operations using pipes is possible.

```elixir
config = ZssService.get_instance %{sid: "PING", broker: "tcp://127.0.0.1:7776", timeout: 1500}
|> ZssService.add_verb({"LIST", MyModule, :my_fun})
|> ZssService.add_verb({"GET", MyModule, :my_other_fun})
```

To start a new worker using this configuration, you can call the run function.

```elixir
{:ok, worker_pid} = ZssService.run(config)
```

The config can be reused to easily start a multitude of workers.

```elixir
Enum.map(0..2, fn _ ->
  {:ok, worker_pid} = ZssService.run(config)
end)
```

## Service verb contract

The functions specified to handle the verb routes should accept two parameters, which are:

| Parameter  | Type  |  Description  |
|------------|-------|---------------|
| payload    | Mixed | Contains the payload to this route. This can be anything the user specifies, but a Map is recommended. |
| message    | Map   | A Map containing the headers property. This in turn, is a (String key) based map which contains request metadata such as the user performing the request.*

\* The message contains more information than just the headers, but it's not intended to modify these properties. These are subject to change, so use at your own risk.

The return value should be a two or three element tuple, with the following properties:

| Property | Type | Description |
|--------|------------|-------------|
| indicator | atom    | Indicates whether the request can be considered succesfull or an error. Signal by :ok | :error respectively.
| payload | Mixed     | The response payload
| code    | Integer   | The status code to return. :ok defaults to 200 and :error to 500. Override by specifying a custom value if needed

## Supervising

No external tool or code to supervise the processes is required. When starting a worker, a supervision tree is started for each worker, which contain all processes associated with this worker (such as heartbeating). In case any of these processes fail, they will fail in isolation and restart themselves.


## Running the example

To run the example, ensure you retrieved the neccesary dependencies.

```mix deps.get```

Afterwards, run the provided example escript by doing.

```mix run ./examples/pong.exs```
