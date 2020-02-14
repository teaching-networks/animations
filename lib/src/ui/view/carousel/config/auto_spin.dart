/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

/// Automatic spinning of the carousel configuration.
class AutoSpinConfig {
  /// Duration of the auto spin.
  final Duration duration;

  /// Whether auto spin is enabled.
  final bool enabled;

  /// Create configuration.
  AutoSpinConfig({
    this.enabled = true,
    this.duration = const Duration(seconds: 5),
  });
}
