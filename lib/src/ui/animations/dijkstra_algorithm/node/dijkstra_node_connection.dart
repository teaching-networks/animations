import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node.dart';
import 'package:meta/meta.dart';

/// Connection to a dijkstra node.
class DijkstraNodeConnection {
  /// Connected [to] this node.
  final DijkstraNode to;

  /// Weight of the connection.
  int _weight;

  /// Create node connection.
  DijkstraNodeConnection({
    @required this.to,
    @required int weight,
  }) : _weight = weight;

  int get weight => _weight;

  set weight(int value) {
    _weight = value;
  }
}
