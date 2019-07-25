import 'dart:html';

import 'package:meta/meta.dart';

/// Class providing info for rendering images.
class ImageInfo {
  /// Map holding cached instances of already loaded images.
  static Map<String, CanvasImageSource> _cachedInstances = Map<String, CanvasImageSource>();

  /// Aspect ratio of the image.
  final double aspectRatio;

  /// Path to the image.
  final String path;

  /// Create image info.
  const ImageInfo({
    @required this.path,
    @required this.aspectRatio,
  });

  /// Load image.
  Future<CanvasImageSource> load() async {
    ImageElement element = _cachedInstances[path];
    if (element != null) {
      return element;
    } else {
      // Load and cache image element.
      element = ImageElement(src: path);

      // Wait until element is loaded.
      await element.onLoad.first;

      _cachedInstances[path] = element;

      return element;
    }
  }

  /// Get the loaded image (if loaded yet, otherwise null).
  CanvasImageSource get image => _cachedInstances[path];

  /// Check whether the image is loaded yet.
  bool get loaded => _cachedInstances[path] != null;
}
