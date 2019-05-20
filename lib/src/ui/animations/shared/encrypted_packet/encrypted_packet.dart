import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/repaintable.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';

/// An packet which can be encrypted multiple times.
/// This is visualized by wrapping the packet in circles which equal the
/// amount of encryption steps the packet has been processed.
class EncryptedPacket extends CanvasDrawable with Repaintable {
  /// Default duration of the encryption and decryption animations.
  static const Duration _defaultAnimationDuration = Duration(seconds: 1);

  /// Maximum angle in a circle.
  static const double _maxAngle = 2 * pi;

  /// Random number generator used by the animation.
  static Random _rng = Random();

  /// Duration of the encryption and decryption animations.
  final Duration animationDuration;

  /// Layers of encryption applied to the packet.
  int _encryptionLayers;

  /// Colors of the encryption layers.
  List<Color> _encryptionLayerColors = List<Color>();

  /// Color of the last encryption layer (during encryption/decryption animation).
  Color _lastEncryptionLayerColor;

  /// Whether to start the encryption/decryption animation.
  bool _animationStarted = false;

  /// Point in time the encryption animation has been started.
  num _animationStartTS;

  /// Whether the animation is an encryption or decryption.
  bool _animationEncryption = false;

  /// Current angle of the encryption layer encryption/decryption animation in progress.
  double _animationAngle;

  /// Start angle of the encryptin/decryption layer in the animation.
  double _animationStartAngle;

  /// Cached image of the previously drawn packet.
  CanvasElement _cacheCanvas = CanvasElement();
  CanvasRenderingContext2D _cacheContext;

  /// Create encrypted packet.
  EncryptedPacket({
    int encryptionLayers = 0,
    this.animationDuration = _defaultAnimationDuration,
  }) : _encryptionLayers = encryptionLayers {
    _cacheContext = _cacheCanvas.getContext("2d");
  }

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
    if (needsRepaint) {
      // Refresh cached canvas content
      _cacheCanvas.width = rect.width.toInt();
      _cacheCanvas.height = rect.height.toInt();

      _cacheContext.clearRect(0, 0, rect.width, rect.height);

      _drawPacket(_cacheContext, max(rect.width, rect.height));

      validate();
    }

    // Only draw content of cached canvas to canvas.
    context.drawImageToRect(_cacheCanvas, rect);
  }

  /// Draw the packet on the passed rendering [context].
  void _drawPacket(CanvasRenderingContext2D context, double size) {
    double offset = size / 2;
    double radius = size / 6;
    double layerLineWidth = radius * 0.1;

    // Draw packet sphere
    setFillColor(context, Colors.SLATE_GREY);
    context.beginPath();
    context.arc(offset, offset, radius, 0, _maxAngle);
    context.fill();

    int layers = animationInProgress && _animationEncryption ? _encryptionLayers - 1 : _encryptionLayers;

    // Draw encryption layers (except the last one).
    context.lineWidth = layerLineWidth;
    for (int i = 0; i < layers; i++) {
      _drawEncryptionLayer(context, _encryptionLayerColors[i], i, offset, radius, _maxAngle);
    }

    if (animationInProgress) {
      _drawEncryptionLayer(context, _lastEncryptionLayerColor, layers, offset, radius, _animationAngle);
    }
  }

  /// Draw an encryption layer.
  void _drawEncryptionLayer(CanvasRenderingContext2D context, Color color, int encryptionLayerIndex, double offset, double baseSize, double endAngle) {
    double layerRadius = baseSize + (window.devicePixelRatio * 5) * (encryptionLayerIndex + 1);

    setStrokeColor(context, color);
    context.beginPath();
    context.arc(offset, offset, layerRadius, _animationStartAngle, _animationStartAngle + endAngle);
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
  void encrypt({
    Color color = Colors.SLATE_GREY,
  }) {
    _encryptionLayers++;
    _lastEncryptionLayerColor = color;
    _encryptionLayerColors.add(color);
    _animationEncryption = true;

    _startAnimation();
  }

  /// Decrypt the packet.
  void decrypt() {
    if (_encryptionLayers <= 0) {
      return;
    }

    _encryptionLayers--;
    _lastEncryptionLayerColor = _encryptionLayerColors.removeLast();
    _animationEncryption = false;

    _startAnimation();
  }

  /// Start the animation next render cycle.
  void _startAnimation() {
    _animationStarted = true;
    _animationStartAngle = 2 * pi * _rng.nextDouble();
  }
}
