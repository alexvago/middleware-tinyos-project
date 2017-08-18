Implement a data collection infrastructure to retrieve the average temperature and humidity in an area. Each node periodically measures the ambient temperature and humidity (under TOSSIM use an emulation of the sensors) and calculates their average since the last COLLECT message (see below).

The sink node periodically broadcasts a message COLLECT that floods the network and triggers data collection. Upon receiving the COLLECT message, each sensor node should return to the sink the average temperature and humidity it calculated, resetting them afterwards. Notice that the network is assumed to be multi-hop, so data sent by each sensor node has to be appropriately forwarded toward the sink by other nodes.

A possible solution to the problem above is to build, during the flooding of the COLLECT message, a spanning tree, used backward to forward data in a multi-hop way.

Make the appropriate choices (e.g., in terms of timeouts and delays) to reduce collisions and to limit the impact of the "ack implosion" phenomenon, which is inherent in this type of data collection protocols.

Test the system in TOSSIM with a network big enough to stress the multi-hop nature of the protocol. Measure the perfomance of the protocol (time to retrieve data, percentage of data retrieved, number of packets used to retrieve it) under different conditions in terms of the total number of nodes and distance among nodes.
