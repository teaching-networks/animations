/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

/// A vertical separator line.
class VerticalSeparatorDrawable extends Drawable {
  /// Color of the separator line.
  final Color color;

  /// Width of the separator line.
  final double lineWidth;

  /// Padding of the line.
  final double yPadding;

  /// Padding in x direction of the line.
  final double xPadding;

  /// Subscription to parent size changes of the current parent.
  StreamSubscription<SizeChange> _parentSizeChangeListener;

  /// Create separator.
  VerticalSeparatorDrawable({
    Drawable parent,
    this.color = Colors.LIGHTGREY,
    this.lineWidth = 1,
    this.yPadding = 0,
    this.xPadding = 2,
  }) : super(parent: parent) {
    _init();
  }

  /// Initialize the drawable.
  void _init() {
    if (hasParent) {
      _onParentChanged(parent);
    }
  }

  @override
  void cleanup() {
    _onParentChanged(null);

    super.cleanup();
  }

  /// What to do when the parent changed.
  Future<void> _onParentChanged(Drawable parent) async {
    if (_parentSizeChangeListener != null) {
      await _parentSizeChangeListener.cancel();
    }

    if (parent != null) {
      _onParentSizeChanged();
      _parentSizeChangeListener = parent.sizeChanges.listen((change) {
        _onParentSizeChanged();
      });
    }
  }

  /// What to do when the parent size changes.
  void _onParentSizeChanged() {
    setSize(
      width: (lineWidth + xPadding * 2) * window.devicePixelRatio,
      height: parent.size.height,
    );
  }

  @override
  void setParent(Drawable parent) {
    super.setParent(parent);

    _onParentChanged(parent);
  }

  @override
  void draw() {
    setStrokeColor(color);
    ctx.lineWidth = lineWidth * window.devicePixelRatio;

    double offset = lineWidth * window.devicePixelRatio / 2;
    double yPad = yPadding * window.devicePixelRatio;
    double xPad = xPadding * window.devicePixelRatio;

    ctx.beginPath();
    ctx.moveTo(offset + xPad, yPad);
    ctx.lineTo(offset + xPad, size.height - yPad);
    ctx.stroke();
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update.
  }

  @override
  bool hasTransientSize() {
    return true;
  }
}
