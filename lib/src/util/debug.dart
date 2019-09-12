/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

/// Utility class for debugging.
class Debug {
  /// Check whether application is running in debug mode.
  static bool get isDebugMode {
    bool debug = false;

    assert(debug = true);

    return debug;
  }
}
