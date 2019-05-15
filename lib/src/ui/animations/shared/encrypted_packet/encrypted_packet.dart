import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/repaintable.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';

/// An packet which can be encrypted multiple times.
/// This is visualized by wrapping the packet in circles which equal the
/// amount of encryption steps the packet has been processed.
class EncryptedPacket extends CanvasDrawable with Repaintable {
  /// Default duration of the encryption and decryption animations.
  static const Duration _defaultAnimationDuration = Duration(seconds: 1);

  /// Maximum angle in a circle.
  static const double _maxAngle = 2 * pi;

  /// Duration of the encryption and decryption animations.
  final Duration animationDuration;

  /// Layers of encryption applied to the packet.
  int _encryptionLayers;

  /// The old encryption layers value (for the animation).
  int _oldEncryptionLayers;

  /// Whether to start the encryption/decryption animation.
  bool _animationStarted = false;

  /// Point in time the encryption animation has been started.
  num _animationStartTS;

  /// Whether the animation is an encryption or decryption.
  bool _animationEncryption = false;

  /// Current angle of the encryption layer encryption/decryption animation in progress.
  double _animationAngle;

  /// Create encrypted packet.
  EncryptedPacket({
    int encryptionLayers = 0,
    this.animationDuration = _defaultAnimationDuration,
  }) : _encryptionLayers = encryptionLayers;

  @override
  void preRender([num timestamp = -1]) {
    super.preRender(timestamp);

    if (timestamp == -1) {
      throw Exception("EncryptedPacket drawable must be provided a timestamp to work properly");
    }

    _checkTimestamps(timestamp);
    _updateAnimationProgress(timestamp);
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    if (!needsRepaint) {
      return;
    }

    context.save();

    double x = rect.left;
    double y = rect.top;
    double size = max(rect.width, rect.height);

    // Draw packet sphere
    context.beginPath();
    context.arc(x, y, size, 0, _maxAngle);
    context.fill();

    int layers = animationInProgress && _animationEncryption ? _encryptionLayers - 1 : _encryptionLayers;

    // Draw encryption layers (except the last one).
    for (int i = 0; i < layers; i++) {
      _drawEncryptionLayer(context, i, x, y, size, _maxAngle);
    }

    if (animationInProgress) {
      _drawEncryptionLayer(context, layers, x, y, size, _animationAngle);
    }

    context.restore();

    validate();
  }

  /// Draw an encryption layer.
  void _drawEncryptionLayer(CanvasRenderingContext2D context, int encryptionLayerIndex, double x, double y, double baseSize, double endAngle) {
    double layerRadius = baseSize + (window.devicePixelRatio * 5) * (encryptionLayerIndex + 1);

    context.beginPath();
    context.arc(x, y, layerRadius, 0, endAngle);
    context.stroke();
  }

  /// Check if timestamps need to be updated.
  void _checkTimestamps(num timestamp) {
    if (_animationStarted) {
      _animationStarted = false;
      _animationStartTS = timestamp;

      invalidate();
    }
  }

  /// Update the current animation state.
  void _updateAnimationProgress(num timestamp) {
    if (animationInProgress) {
      double progress = Curves.easeInOutCubic(_getProgress(_animationStartTS, timestamp));

      if (progress >= 1.0) {
        _animationStartTS = null;
      } else {
        // Update animation to match the progress.
        if (!_animationEncryption) {
          progress = 1.0 - progress; // Reverse animation
        }

        _animationAngle = _maxAngle * progress;
        invalidate();
      }
    }
  }

  /// Get the animation progress defined by the passed [startTS] (start timestamp) and [curTS] (current timestamp).
  double _getProgress(num startTS, num curTS) {
    return (curTS - startTS) / animationDuration.inMilliseconds;
  }

  bool get animationInProgress => _animationStartTS != null;

  /// Encrypt the packet once more.
  void encrypt() {
    _oldEncryptionLayers = _encryptionLayers;
    _encryptionLayers++;
    _animationEncryption = true;

    _startAnimation();
  }

  /// Decrypt the packet.
  void decrypt() {
    _oldEncryptionLayers = _encryptionLayers;
    _encryptionLayers--;
    _animationEncryption = false;

    _startAnimation();
  }

  /// Start the animation next render cycle.
  void _startAnimation() {
    _animationStarted = true;
  }
}
