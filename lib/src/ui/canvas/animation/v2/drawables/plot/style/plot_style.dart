/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'coordinate_system_style.dart';

/// Style of the plot.
class PlotStyle {
  /// Style of the coordinate system or null if no coordinate system should be shown.
  final CoordinateSystemStyle coordinateSystem;

  /// Create the style for the plot.
  const PlotStyle({
    this.coordinateSystem,
  });
}
