/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node.dart';

/// State of a dijkstra node during the algorithm.
class DijkstraNodeState {
  /// Predecessors of the node during the algorithm.
  List<DijkstraNode> _predecessors = List<DijkstraNode>();

  /// Current distance to the start node.
  int _distance;

  /// Whether the node has already been visited.
  bool _visited = false;

  List<DijkstraNode> get predecessors => _predecessors;

  set predecessors(List<DijkstraNode> value) {
    _predecessors = value;
  }

  int get distance => _distance;

  set distance(int value) {
    _distance = value;
  }

  /// Reset the state.
  void reset() {
    _predecessors.clear();
    _distance = null;
    _visited = false;
  }

  bool get visited => _visited;

  set visited(bool value) {
    _visited = value;
  }
}
