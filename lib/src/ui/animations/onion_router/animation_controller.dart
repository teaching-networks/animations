abstract class AnimationController {
  /// Invalidate the animation, causing a rebuild.
  BuildInfo invalidate();

  /// Get info about the current rebuild.
  BuildInfo getBuildInfo();
}

class BuildInfo {
  /// Whether everything should be rebuilt.
  bool rebuild;

  BuildInfo({
    this.rebuild = true,
  });

  void reset() {
    rebuild = true;
  }
}
