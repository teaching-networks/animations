import 'dart:collection';

import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node_connection.dart';

/// A Dijkstra algorithm implementation.
class Dijkstra {
  /// The set holding the dijkstra nodes to process later.
  Set<DijkstraNode> _toProcess = Set<DijkstraNode>();

  /// Initialize the algorithm.
  initialize(DijkstraNode start, List<DijkstraNode> nodes) {
    _toProcess.clear();

    /// Set distance to infinity and clear predecessors.
    for (final node in nodes) {
      node.state.reset();
    }

    start.state.distance = 0;
    _toProcess.add(start);
  }

  /// Calculate the next step.
  void nextStep() {
    if (isFinished) {
      return; // Algorithm already finished -> nextStep() has no effect
    }

    // Sort the nodes waiting to get processed
    List<DijkstraNode> sortedQueue = _toProcess.toList();
    sortedQueue.sort((node1, node2) => node1.state.distance.compareTo(node2.state.distance));

    // Take the first node
    DijkstraNode nodeToProcess = sortedQueue.first;
    _toProcess.remove(nodeToProcess); // Remove it from the Set
    nodeToProcess.state.visited = true; // Flag node as visited

    // Go through all nodes this node is connected to and update distances if they are lower than the existing
    if (nodeToProcess.connectedTo != null) {
      for (DijkstraNodeConnection connectedTo in nodeToProcess.connectedTo) {
        int oldDistance = connectedTo.to.state.distance;
        int newDistance = nodeToProcess.state.distance + connectedTo.weight;

        if (oldDistance == null || newDistance < oldDistance) {
          connectedTo.to.state.distance = newDistance;
        }

        if (!connectedTo.to.state.visited) {
          // If node has not already been visited, schedule visit via Set for one of the next steps!
          _toProcess.add(connectedTo.to);
        }
      }
    }
  }

  /// Reset the algorithm state.
  void reset() {
    _toProcess.clear();
  }

  /// Whether the algorithm already finished.
  bool get isFinished => _toProcess.isEmpty;
}
