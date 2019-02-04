import 'dart:collection';

import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node.dart';

/// A Dijkstra algorithm implementation.
class Dijkstra {
  /// The queue holding the dijkstra nodes to check later.
  List<DijkstraNode> _nodeQueue = List<DijkstraNode>();

  /// Initialize the algorithm.
  initialize(DijkstraNode start, List<DijkstraNode> nodes) {
    _nodeQueue.clear();

    /// Set distance to infinity and clear predecessors.
    for (final node in nodes) {
      node.state.reset();
    }

    start.state.distance = 0;
    _nodeQueue.add(start);
  }

  /// Calculate the next step.
  void nextStep() {
    _nodeQueue.sort((node1, node2) => node1.state.distance.compareTo(node2.state.distance));


    // TODO
  }

}
