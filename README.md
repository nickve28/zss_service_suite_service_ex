# ZSS ZeroMQ Service

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

## Running the example

To run the example, ensure you retrieved the neccesary dependencies.

```mix deps.get```

Afterwards, run the provided example shell script.

```./examples/pong.sh```

