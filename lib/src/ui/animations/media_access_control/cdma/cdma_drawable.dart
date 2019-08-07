/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/animations/media_access_control/cdma/graph/signal_graph.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/input/input_drawable.dart';

/// Main drawable for the CDMA animation.
class CDMADrawable extends Drawable {
  SignalGraph _signalGraph;

  InputDrawable _input;

  /// Create drawable.
  CDMADrawable() {
    _init();
  }

  /// Initialize the drawable.
  void _init() {
    _signalGraph = SignalGraph(parent: this, signal: [0, 0, 0, 5, -3, 2, 1, 0, 0, 1, -1, 0, 1, 1, 1, 0]);
    _input = InputDrawable(parent: this, fontFamily: 'Roboto');
  }

  @override
  void draw() {
    _signalGraph.render(ctx, lastPassTimestamp);
    _input.render(ctx, lastPassTimestamp, x: 300, y: 600);
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update.
  }
}
