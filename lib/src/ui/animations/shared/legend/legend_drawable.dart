/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'package:hm_animations/src/ui/animations/shared/legend/color_box.dart';
import 'package:hm_animations/src/ui/animations/shared/legend/legend_item.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/grid_layout.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/horizontal_alignment.dart';
import 'package:hm_animations/src/ui/canvas/text/alignment.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';

/// Drawable used to display a legend explaining color meanings.
class LegendDrawable extends Drawable {
  /// Items to display in the legend.
  List<LegendItem> items;

  /// Spacing between the items.
  final double spacing;

  /// List of text drawables showing the labels of the legend items.
  List<TextDrawable> _labelDrawables;

  /// Grid layout the legend items are positioned in.
  GridLayout _gridLayout;

  /// Create drawable.
  LegendDrawable({
    this.items,
    this.spacing = 2,
  }) {
    _init();
  }

  /// Update items in the drawable.
  void updateItems(List<LegendItem> items) {
    this.items = items;
    _init();
  }

  /// Initialize the legend drawable.
  void _init() {
    _labelDrawables = List.generate(
        items.length,
        (index) => TextDrawable(
              text: items[index].text,
              alignment: TextAlignment.LEFT,
            ));

    _gridLayout = GridLayout(
      parent: this,
      padding: spacing / 2 * window.devicePixelRatio,
      horizontalAlignment: HorizontalAlignment.LEFT,
      cells: [
        for (int row = 0; row < items.length; row++)
          for (int column = 0; column < 2; column++)
            CellSpec(
              drawable: column == 0
                  ? (ColorBox(color: items[row].color)
                    ..setSize(
                      width: _labelDrawables[row].size.height,
                      height: _labelDrawables[row].size.height,
                    ))
                  : _labelDrawables[row],
              row: row,
              column: column,
            ),
      ],
    );

    setSize(
      width: _gridLayout.size.width,
      height: _gridLayout.size.height,
    );
  }

  @override
  void draw() {
    _gridLayout.render(ctx, lastPassTimestamp);
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Do nothing.
  }
}
