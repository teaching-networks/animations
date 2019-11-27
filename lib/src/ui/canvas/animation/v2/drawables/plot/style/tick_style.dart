/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';

/// Generator to generate a list of ticks between [min] and [max].
typedef List<double> TicksGenerator(double min, double max);

/// Renderer of a tick value.
typedef String TickLabelRenderer(double tick);

/// Define the tick style for an axis.
class TickStyle {
  /// Generator to show ticks on the axis.
  final TicksGenerator generator;

  /// Size of the tick line.
  final int size;

  /// Color to use for the ticks. Leave null to inherit the axis color.
  final Color color;

  /// Font size of the tick labels.
  final double labelFontSize;

  /// Color of the tick labels.
  final Color labelColor;

  /// Renderer of a tick label (leave to null for the default renderer).
  final TickLabelRenderer labelRenderer;

  const TickStyle({
    @required this.generator,
    this.size = 8,
    this.color,
    this.labelFontSize = 12,
    this.labelColor = Colors.BLACK,
    this.labelRenderer,
  });

  /// Get a ticks generator which will generate a fixed amount of ticks.
  static TicksGenerator fixedCountTicksGenerator(int count) => (min, max) {
        if (count < 2) {
          throw new Exception("Generator needs a tick count of at least 2");
        }

        double increase = (max - min) / (count - 1);
        return List.generate(count, (index) => min + increase * index);
      };

  /// Tick label renderer only rendering the passed precision.
  static TickLabelRenderer precisionTickLabelRenderer(int precision) => (tick) {
        return tick.toStringAsPrecision(precision);
      };
}
