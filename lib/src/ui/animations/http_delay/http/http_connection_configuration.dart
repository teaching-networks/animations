/// Configuration for http connections.
class HttpConnectionConfiguration {

  /// Count of parallel connections.
  /// 1 for single threaded connection.
  final int parallelConnectionCount;

  /// Count of objects which need to be transferred.
  final int objectCount;

  /// Object transmission delay in RTT
  final double objectTransmissionDelay;

  /// Whether the connection should use pipelining (only applicable with persistent connections).
  final bool withPipelining;

  HttpConnectionConfiguration({
    this.objectCount = 1,
    this.objectTransmissionDelay = 0.0,
    this.parallelConnectionCount = 1,
    this.withPipelining = false
  });

  bool get hasParallelConnections => parallelConnectionCount > 1;

}
