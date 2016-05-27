[![Build Status](https://travis-ci.org/Eurex-Clearing-Messaging-Interfaces/Dispatch-Examples.svg?branch=master)](https://travis-ci.org/Eurex-Clearing-Messaging-Interfaces/Dispatch-Examples)

# Apache Qpid Dispatch examples

## Apache Qpid Dispatch

The Dispatch router is an AMQP 1.0 router that provides advanced interconnect for AMQP. It is not a broker. It will never assume ownership of a message. It will, however, propagate settlement and disposition across a network such that delivery guarantees are met.

It can be used together with Eurex Clearing AMQP interfaces, which support AMQP 1.0. More details about Dispatch router can be found on [Apache Qpid website](http://qpid.apache.org/components/dispatch-router/index.html)

*These examples are currently written and tested against development versions of Qpid Dispatch 0.6.0.*

## Use cases

Dispatch router enables many new use cases which were not possible in the past:
- **Network security:** Only the Dispatch router needs to be able to connect to the outside to the AMQP broker. All clients connect only "locally" to the router and don't need any access to outside networks. 
- **Private key protection:** Only the Dispatch router needs to have the SSL certificate required to authenticate on the AMQP broker. It doesn't need to be stored on the hosts where the clients are running.
- **Connection concentration:** Multiple clients can be connected to the Dispatch router to send / receive messages. Dispatch will maintain only one connection to the AMQP broker on Eurex side and route all these messages through this single connection
- **Connection splitting:** Dispatch can maintain multiple different connections to different Eurex Clearing AMQP brokers (e.g. to FIXML Interface for listed derivatives clearing and FpML Interface for OTC derivatives clearing) or to the same service, but with different accounts (e.g. several connections to FIXML Interface, but each for different member). The client needs only single connection to the Dispatch router to make use of all Dispatch's connections to different services / accounts.

## Link routing versus Message routing

Dispatch can be configured in two different modes - link routing or message routing. In link routing mode, AMQP links (i.e. message receivers or message senders) created by the clients will be propagated through the Dispatch router to the broker. In the message routing mode, Dispatch will open its own links with the broker and forward only the messages between the clients and broker. Both modes can be used against Eurex AMQP brokers.

## Example configuration

The example configuration in this repository covers all the use cases mentioned above. It opens two different connections to the FIXML broker using two different accounts:
- ABCFR_ABCFRALMMACC1
- DEFFR_DEFFRALMMACC1

The authentication against the FIXML broker is using SSL Client Authentication.

Additionally, it sets up an listener which is using username / password authentication and has two accounts for user1 and user2. The access control policy is configured to allow user1 to receive all broadcasts as well as send requests and receive response. user1 is allowed to received broadcasts, but not to send any requests or receive responses.

There are two separate example configurations. One is using the message routing and the other is using the link routing.

To use the examples in different environment, the hostnames / port numbers and the SSL certificates have to be adapted.

## Integration tests

The project is using Travis-CI to run its own integration tests. The tests are executed using Docker images which contain the AMQP broker with configuration corresponding to Eurex Clearing FIXML Interface as well as the Dispatch router. The details of the Travis-CI integration can be found in the .travis.yml file.

## Documentation

More information about using Dispatch router together with Eurex Clearing AMQP interfaces can be found on the [Effective Messaging blog](http://blog.effectivemessaging.com/2016/05/connecting-to-eurex-clearing-with.html). More details about Eurex Clearing Messaging Interfaces can be found on [Eurex Clearing website](http://www.eurexclearing.com/clearing-en/technology/eurex-release14/system-documentation/system-documentation/861464?frag=861450)
