import 'dart:math';

import 'package:hm_animations/src/ui/animations/shared/generator/cloud_generator/cloud_generator.dart';

/// Mixin providing reusable functionality within onion router scenario drawables.
mixin ScenarioDrawable {
  /// How many relay nodes to display.
  static const int _relayNodeCount = 20;

  /// Generate the relay nodes to show.
  Future<List<Point<double>>> generateRelayNodes({
    int nodeCount = _relayNodeCount,
  }) async {
    return CloudGenerator.generate(_relayNodeCount, minDistance: 0.2);
  }
}
