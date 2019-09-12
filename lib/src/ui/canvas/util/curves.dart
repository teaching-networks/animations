/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

/// Type of a curve function.
typedef double Curve(double p);

/**
 * Class helping with curved animations.
 */
class Curves {
  /**
   * Pass value of range [0.0, 1.0] and get the linear equivalent (which is the same).
   */
  static double linear(double p) => p;

  /**
   * Accelerating from zero velocity.
   * Pass value of range [0.0, 1.0] and get the ease in quad curved equivalent in range [0.0, 1.0].
   */
  static double easeInQuad(double p) => p * p;

  /**
   * Decelerating to zero velocity.
   * Pass value of range [0.0, 1.0] and get the equivalent in range [0.0, 1.0].
   */
  static double easeOutQuad(double p) => p * (2 - p);

  /**
   * Acceleration until halfway, then deceleration.
   * Pass value of range [0.0, 1.0] and get the equivalent in range [0.0, 1.0].
   */
  static double easeInOutQuad(double p) => p < 0.5 ? (2 * p * p) : (-1 + (4 - 2 * p) * p);

  /**
   * Accelerating from zero velocity.
   * Pass value of range [0.0, 1.0] and get the equivalent in range [0.0, 1.0].
   */
  static double easeInCubic(double p) => p * p * p;

  /**
   * Decelerating to zero velocity
   * Pass value of range [0.0, 1.0] and get the equivalent in range [0.0, 1.0].
   */
  static double easeOutCubic(double p) => (--p) * p * p + 1;

  /**
   * Acceleration until halfway, then deceleration.
   * Pass value of range [0.0, 1.0] and get the equivalent in range [0.0, 1.0].
   */
  static double easeInOutCubic(double p) => p < 0.5 ? (4 * p * p * p) : ((p - 1) * (2 * p - 2) * (2 * p - 2) + 1);

  /**
   * Accelerating from zero velocity.
   * Pass value of range [0.0, 1.0] and get the equivalent in range [0.0, 1.0].
   */
  static double easeInQuart(double p) => p * p * p * p;

  /**
   * Decelerating to zero velocity.
   * Pass value of range [0.0, 1.0] and get the equivalent in range [0.0, 1.0].
   */
  static double easeOutQuart(double p) => 1 - (--p) * p * p * p;

  /**
   * Acceleration until halfway, then deceleration.
   * Pass value of range [0.0, 1.0] and get the equivalent in range [0.0, 1.0].
   */
  static double easeInOutQuart(double p) => p < 0.5 ? (8 * p * p * p * p) : (1 - 8 * (--p) * p * p * p);

  /**
   * Accelerating from zero velocity.
   * Pass value of range [0.0, 1.0] and get the equivalent in range [0.0, 1.0].
   */
  static double easeInQuint(double p) => p * p * p * p * p;

  /**
   * Decelerating to zero velocity.
   * Pass value of range [0.0, 1.0] and get the equivalent in range [0.0, 1.0].
   */
  static double easeOutQuint(double p) => 1 + (--p) * p * p * p * p;

  /**
   * Acceleration until halfway, then deceleration.
   * Pass value of range [0.0, 1.0] and get the equivalent in range [0.0, 1.0].
   */
  static double easeInOutQuint(double p) => p < 0.5 ? (16 * p * p * p * p * p) : (1 + 16 * (--p) * p * p * p * p);
}
