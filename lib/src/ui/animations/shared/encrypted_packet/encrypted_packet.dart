import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim_helper.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';

/// An packet which can be encrypted multiple times.
/// This is visualized by wrapping the packet in circles which equal the
/// amount of encryption steps the packet has been processed.
class EncryptedPacket extends Drawable {
  /// Default duration of the encryption and decryption animations.
  static const Duration _defaultAnimationDuration = Duration(seconds: 1);

  /// Maximum angle in a circle.
  static const double _maxAngle = 2 * pi;

  /// Random number generator used by the animation.
  static Random _rng = Random();

  /// Duration of the encryption and decryption animations.
  final Duration animationDuration;

  /// Encryption/Decryption animation of the packet.
  AnimHelper _animation;

  /// Layers of encryption applied to the packet.
  int _encryptionLayers;

  /// Colors of the encryption layers.
  List<Color> _encryptionLayerColors = List<Color>();

  /// Color of the last encryption layer (during encryption/decryption animation).
  Color _lastEncryptionLayerColor;

  /// Whether the animation is an encryption or decryption.
  bool _animationEncryption = false;

  /// Start angle of the encryptin/decryption layer in the animation.
  double _animationStartAngle = 0;

  double _packetSize = 0;

  int _maxEncryptionLayers = 3;

  /// Create encrypted packet.
  EncryptedPacket({
    Drawable parent,
    int encryptionLayers = 0,
    this.animationDuration = _defaultAnimationDuration,
  })  : _encryptionLayers = encryptionLayers,
        _animation = AnimHelper(
          duration: animationDuration,
          curve: Curves.easeInOutCubic,
        ),
        super(parent: parent);

  set packetSize(double value) {
    _packetSize = value;

    setSize(
      width: value,
      height: value,
    );
  }

  set maxEncryptionLayers(int value) {
    _maxEncryptionLayers = value;

    while (_encryptionLayers > _maxEncryptionLayers) {
      decrypt(withAnimation: false);
    }
  }

  @override
  void update(num timestamp) {
    _animation.update(timestamp);
  }

  @override
  void draw() {
    _drawPacket(ctx, _packetSize);
  }

  @override
  Point<double> calculateRenderingPosition(double x, double y) => Point<double>(x - size.width / 2, y - size.height / 2);

  @override
  bool needsRepaint() => _animation.running;

  /// Draw the packet on the passed rendering [context].
  void _drawPacket(CanvasRenderingContext2D context, double size) {
    double offset = size / 2;
    double radius = size / 6;
    double layerLineWidth = (size - radius * 2) / _maxEncryptionLayers / 2;

    // Draw packet sphere
    setFillColor(Colors.CORAL);
    context.beginPath();
    context.arc(offset, offset, radius, 0, _maxAngle);
    context.fill();

    int layers = _animation.running && _animationEncryption ? _encryptionLayers - 1 : _encryptionLayers;

    // Draw encryption layers (except the last one).
    context.lineWidth = layerLineWidth;
    for (int i = 0; i < layers; i++) {
      _drawEncryptionLayer(context, _encryptionLayerColors[i], i, offset, radius, _maxAngle, layerLineWidth);
    }

    if (_animation.running) {
      double animationAngle = _maxAngle * _animation.progress;
      _drawEncryptionLayer(context, _lastEncryptionLayerColor, layers, offset, radius, animationAngle, layerLineWidth);
    }
  }

  /// Draw an encryption layer.
  void _drawEncryptionLayer(
    CanvasRenderingContext2D context,
    Color color,
    int encryptionLayerIndex,
    double offset,
    double baseSize,
    double endAngle,
    double layerLineWidth,
  ) {
    double layerRadius = baseSize + layerLineWidth * encryptionLayerIndex + layerLineWidth / 2;

    setStrokeColor(color);
    context.beginPath();
    context.arc(offset, offset, layerRadius, _animationStartAngle, _animationStartAngle + endAngle);
    context.stroke();
  }

  /// Encrypt the packet once more.
  Future<void> encrypt({
    Color color = Colors.SLATE_GREY,
    bool withAnimation = true,
  }) {
    _encryptionLayers++;
    if (_encryptionLayers > _maxEncryptionLayers) {
      throw Exception("Cannot encrypt when the maximum encryption layer amount has been reached. Set via EcryptedPacket.maxEncryptionLayers = ...");
    }

    _lastEncryptionLayerColor = color;
    _encryptionLayerColors.add(color);
    _animationEncryption = true;

    if (withAnimation) {
      if (_animation.reversed) _animation.reverse();
      _startAnimation();
      return Future.delayed(animationDuration);
    } else {
      return Future.value(null);
    }
  }

  /// Decrypt the packet.
  Future<void> decrypt({
    bool withAnimation = true,
  }) {
    if (_encryptionLayers <= 0) {
      return Future.value(null);
    }

    _encryptionLayers--;
    _lastEncryptionLayerColor = _encryptionLayerColors.removeLast();
    _animationEncryption = false;

    if (withAnimation) {
      if (!_animation.reversed) _animation.reverse();
      _startAnimation();
      return Future.delayed(animationDuration);
    } else {
      return Future.value(null);
    }
  }

  /// Reset the packet.
  void reset() {
    _encryptionLayers = 0;
    _encryptionLayerColors.clear();
    _animationEncryption = false;
    _animation.reset();

    invalidate();
  }

  /// Start the animation next render cycle.
  void _startAnimation() {
    _animationStartAngle = 2 * pi * _rng.nextDouble();
    _animation.start();
  }
}
