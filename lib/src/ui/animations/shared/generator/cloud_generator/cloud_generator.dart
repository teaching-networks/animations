/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

/// Generator of a "cloud".
/// Will generate random points with a given minimum distance.
class CloudGenerator {
  /// Generate a cloud.
  /// Specify the point size and minimum distance between the points.
  static List<Point<double>> generate(
    int size, {
    double minDistance = 0.1,
    Random rng,
  }) {
    if (rng == null) {
      rng = Random();
    }

    List<Point<double>> points = List<Point<double>>(size);

    for (int i = 0; i < size; i++) {
      points[i] = Point<double>(rng.nextDouble(), rng.nextDouble());

      // Check if too near to a point
      for (int a = 0; a < i; a++) {
        if (points[i].distanceTo(points[a]) < minDistance) {
          i--; // Point is too near! Regenerate.
          break;
        }
      }
    }

    return points;
  }
}
