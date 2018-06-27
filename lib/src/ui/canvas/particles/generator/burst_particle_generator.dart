import 'dart:html';

import 'package:hm_animations/src/ui/canvas/particles/burst_particle.dart';
import 'package:hm_animations/src/ui/canvas/particles/generator/particle_generator.dart';
import 'package:hm_animations/src/ui/canvas/particles/particle.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

class BurstParticleGenerator extends ParticleGenerator {
  int count;
  Point<num> center;
  Color color;
  num minRadius;
  num maxRadius;
  double gravity;
  double shrink;
  double opacity;
  bool repeating;

  List<Particle> _particles = new List<Particle>();

  BurstParticleGenerator(
      {this.count = 50,
      this.center = const Point(0, 0),
      this.color = Colors.AMBER,
      this.minRadius = 5,
      this.maxRadius = 20,
      this.gravity = 0.1,
      this.shrink = 0.05,
      this.opacity = 0.01,
      this.repeating = false});

  @override
  void start() {
    _particles.clear();

    for (int i = 0; i < count; i++) {
      _particles.add(new BurstParticle(
          color: color,
          minRadius: minRadius,
          maxRadius: maxRadius,
          gravity: gravity,
          shrink: shrink,
          opacity: opacity,
          x: center.x,
          y: center.y,
          repeating: repeating)
        ..init());
    }
  }

  @override
  void draw(CanvasRenderingContext2D context, num timestamp) {
    for (Particle particle in _particles) {
      particle.draw(context, timestamp);
    }
  }
}
