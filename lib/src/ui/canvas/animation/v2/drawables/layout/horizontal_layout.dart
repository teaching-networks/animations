/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/layout.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/vertical_alignment.dart';
import 'package:hm_animations/src/util/size.dart';
import 'package:meta/meta.dart';

import 'layout_mode.dart';

/// Layout arranging multiple drawables horizontally.
class HorizontalLayout extends Layout {
  /// Children to lay out.
  final List<Drawable> children;

  /// Layout mode of the layout.
  final LayoutMode layoutMode;

  /// Alignment of the child drawables along the horizontal axis.
  final VerticalAlignment alignment;

  /// Create layout
  HorizontalLayout({
    @required this.children,
    Drawable parent,
    this.layoutMode = LayoutMode.FIT,
    this.alignment = VerticalAlignment.TOP,
  }) : super(parent: parent) {
    _init();
  }

  /// Initialize the layout.
  void _init() {
    _recalculateSize();
  }

  /// Recalculate the size of the layouts drawable.
  void _recalculateSize() {
    switch (layoutMode) {
      case LayoutMode.FIT:
        _recalculateSizeFitMode();
        break;
      case LayoutMode.GROW:
        _recalculateSizeGrowMode();
        break;
      default:
        throw Exception("Layout mode unknown");
    }
  }

  void _recalculateSizeFitMode() {
    double width = 0;
    double height = 0;

    for (Drawable child in children) {
      Size childSize = child.size;

      height = max(height, childSize.height);
      width += childSize.width;
    }

    setSize(
      width: width,
      height: height,
    );
  }

  void _recalculateSizeGrowMode() {
    if (parent != null) {
      setSize(
        width: parent.size.width,
        height: parent.size.height,
      );
    }
  }

  @override
  void setParent(Drawable parent) {
    super.setParent(parent);

    _recalculateSize();
  }

  @override
  void layout() {
    if (children == null || children.isEmpty) {
      return;
    }

    double x = 0;
    for (Drawable child in children) {
      child.render(ctx, lastPassTimestamp, x: x, y: _calculateAlignmentOffset(child));
      x += child.size.width;
    }
  }

  double _calculateAlignmentOffset(Drawable child) {
    switch (alignment) {
      case VerticalAlignment.TOP:
        return 0;
      case VerticalAlignment.BOTTOM:
        return size.height - child.size.height;
      case VerticalAlignment.CENTER:
        return (size.height - child.size.height) / 2;
      default:
        throw Exception("Horizontal alignment unknown");
    }
  }

  @override
  void onChildSizeChange(SizeChange change) {
    if (layoutMode == LayoutMode.FIT) {
      _recalculateSize();
    }
  }

  @override
  void onParentSizeChange(SizeChange change) {
    if (layoutMode == LayoutMode.GROW) {
      double width = change.newSize.width / children.length;
      double height = change.newSize.height;

      for (Drawable child in children) {
        child.setSize(
          width: width,
          height: height,
        );
      }

      setSize(
        width: change.newSize.width,
        height: change.newSize.height,
      );
    }
  }
}
