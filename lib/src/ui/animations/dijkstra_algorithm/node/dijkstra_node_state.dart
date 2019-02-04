import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node.dart';

/// State of a dijkstra node during the algorithm.
class DijkstraNodeState {
  /// Predecessors of the node during the algorithm.
  List<DijkstraNode> _predecessors = List<DijkstraNode>();

  /// Current distance to the start node.
  int _distance;

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
  }
}
