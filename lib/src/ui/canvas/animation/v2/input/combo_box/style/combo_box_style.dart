/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

/// Style settings of the combo box drawable.
class ComboBoxStyle {
  /// Background color of the combo box.
  final Color backgroundColor;

  /// Color of a label.
  final Color labelColor;

  /// Padding of items.
  final double itemPadding;

  /// Create style.
  const ComboBoxStyle({
    this.backgroundColor = Colors.WHITE,
    this.labelColor = Colors.BLACK,
    this.itemPadding = 4,
  });
}
