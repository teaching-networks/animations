import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/particles/particle.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

class BurstParticle extends Particle {
  static Random rng = new Random();

  Color color;
  num minRadius;
  num maxRadius;
  double gravity;
  double shrink;
  double opacity;
  num x;
  num y;
  bool repeating;

  num _birthTimestamp;
  num _radius;
  double _opacity;
  num _curX;
  num _curY;
  num _vx;
  num _vy;

  BurstParticle({this.color = Colors.BLACK, this.minRadius = 5, this.maxRadius = 20, this.gravity = 0.1, this.shrink = 0.05, this.opacity = 0.01, this.x = 0, this.y = 0, this.repeating = false});

  @override
  void draw(CanvasRenderingContext2D context, num timestamp) {
    num diff = timestamp - _birthTimestamp;
    double fractionOfASecond = diff / 1000;

    // Update particle state
    _curX += _vx * fractionOfASecond;
    _curY += _vy * fractionOfASecond;

    _vy += gravity * fractionOfASecond;

    _radius = (_radius - shrink * fractionOfASecond).abs();
    
    _opacity -= max(opacity * fractionOfASecond, 0.0);

    // Draw particle
    context.beginPath();
    context.arc(_curX, _curY, _radius, 0, 2*pi, false);
    setFillColor(context, Color.opacity(color, _opacity));
    context.fill();

    if (_opacity == 0.0 || _radius <= 1.0) {
      kill(); // Kill the particle because it is no more visible.
    }
  }

  @override
  void init() {
    super.init();

    // Generate radius
    _radius = (minRadius + (maxRadius - minRadius) * rng.nextDouble()).roundToDouble();

    // Generate direction vector
    _vx = rng.nextDouble() * maxRadius - maxRadius / 2;
    _vy = rng.nextDouble() * maxRadius - maxRadius / 2;

    _curX = x;
    _curY = y;

    _opacity = 1.0;

    // Save when the particle was born
    _birthTimestamp = window.performance.now();
  }

  @override
  void onDead() {
    if (repeating) {
      this.init(); // Revive this particle.
    }
  }
}
