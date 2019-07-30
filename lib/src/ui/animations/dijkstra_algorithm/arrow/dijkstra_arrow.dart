/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node_connection.dart';
import 'package:meta/meta.dart';

/// An arrow from one dijkstra node to another.
class DijkstraArrow {
  /// Weight of the arrow.
  final DijkstraNodeConnection connection;

  /// Bounds of the arrows weight on the canvas.
  Rectangle<double> _weightBounds;

  /// Create arrow.
  DijkstraArrow({
    @required this.connection,
    @required Rectangle<double> weightBounds,
  }) : _weightBounds = weightBounds;

  Rectangle<double> get weightBounds => _weightBounds;

  set weightBounds(Rectangle<double> value) {
    _weightBounds = value;
  }
}
