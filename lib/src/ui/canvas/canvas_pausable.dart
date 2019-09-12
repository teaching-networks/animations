/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

/**
 * Pausable canvas.
 */
mixin CanvasPausableMixin {
  /**
   * Whether the animation is paused.
   */
  bool _isPaused = false;

  /**
   * When the animation has been paused.
   */
  num _pauseTimestamp;

  /**
   * Pause / unpause animation.
   */
  void switchPause({bool pauseAnimation}) {
    _isPaused = pauseAnimation != null ? pauseAnimation : !_isPaused;

    switchPauseSubAnimations();

    if (_isPaused) {
      _pauseTimestamp = window.performance.now();
    } else {
      num diff = window.performance.now() - _pauseTimestamp;

      unpaused(diff);
    }
  }

  /**
   * Check whether the packet animation is paused.
   */
  bool get isPaused => _isPaused;

  /// Timestamp of the pause.
  num get pauseTimestamp => _pauseTimestamp;

  /**
   * Pause animations that are not in your direct control.
   */
  void switchPauseSubAnimations();

  /**
   * Called when the animation has been unpaused.
   * The time the animation has been paused is passed.
   */
  void unpaused(num timestampDifference);
}
