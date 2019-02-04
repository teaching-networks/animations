/// Utility class for debugging.
class Debug {
  /// Check whether application is running in debug mode.
  static bool get isDebugMode {
    bool debug = false;

    assert(debug = true);

    return debug;
  }
}
