import 'dart:convert';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node.dart';

/// Serializer for a Dijkstra model.
class DijkstraModelSerializer {
  /// Serialized the passed model.
  static String serialize(List<DijkstraNode> nodes) {
    List<Map<String, dynamic>> serializedNodes = [];

    for (final node in nodes) {
      serializedNodes.add(_serializeNode(node));
    }

    return json.encode(serializedNodes);
  }

  /// Serialize the passed node.
  static Map<String, dynamic> _serializeNode(DijkstraNode node) => {
        "id": node.id,
        "size": node.size,
        "coordinates": {
          "x": node.coordinates.x,
          "y": node.coordinates.y,
        },
        "connected_to": node.connectedTo != null
            ? node.connectedTo
                .map((connection) => {
                      "weight": connection.weight,
                      "node_id": connection.to.id,
                    })
                .toList()
            : [],
      };

  /// Deserialize the passed serialized model.
  static List<DijkstraNode> deserialize(String serialized) {
    List<dynamic> serializedNodes = json.decode(serialized);
    List<DijkstraNode> nodes = List<DijkstraNode>();

    for (Map<String, dynamic> serializedNode in serializedNodes) {
      nodes.add(_deserializeNode(serializedNode));
    }

    // Create node lookup
    Map<int, DijkstraNode> nodeLookup = Map<int, DijkstraNode>();
    for (final node in nodes) {
      nodeLookup[node.id] = node;
    }

    // Connect nodes
    for (int i = 0; i < nodes.length; i++) {
      Map<String, dynamic> map = serializedNodes[i];
      DijkstraNode node = nodes[i];

      List<dynamic> connectedToSerialized = map["connected_to"];

      for (Map<String, dynamic> connectionSerialized in connectedToSerialized) {
        int weight = connectionSerialized["weight"];
        int id = connectionSerialized["node_id"];

        DijkstraNode connectedToNode = nodeLookup[id];
        assert(connectedToNode != null);

        node.connectTo(
          connectedToNode,
          weight: weight,
        );
      }
    }

    return nodes;
  }

  /// Deserialize the passed node map.
  static DijkstraNode _deserializeNode(Map<String, dynamic> serializedNode) {
    int id = serializedNode["id"];
    double size = serializedNode["size"];
    Point<double> coordinates = Point<double>(serializedNode["coordinates"]["x"], serializedNode["coordinates"]["y"]);

    return DijkstraNode(
      id: id,
      size: size,
      coordinates: coordinates,
    );
  }
}
