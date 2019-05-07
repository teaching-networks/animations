import 'dart:collection';
import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/queue_simulation/router/queue_packet.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/particles/generator/burst_particle_generator.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';

class QueueRouter extends CanvasDrawable {

  int queueSize;

  Queue<QueuePacket> _queue = new Queue<QueuePacket>();

  CanvasImageSource router;

  BurstParticleGenerator _particleGenerator = new BurstParticleGenerator(opacity: 0.1, minRadius: 3.0, maxRadius: 30.0, count: 50, gravity: 1.0);

  QueueRouter(this.queueSize) {
    _loadImages();
  }

  void _loadImages() async {
    router = await Images.routerIconImage.load();
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    {
      context.translate(rect.left, rect.top);

      double padding = rect.width * 0.02;
      double queueWidth = rect.width * 0.7 - padding;

      context.save();
      {
        context.translate(0.0, rect.height / 2);
        _particleGenerator.render(context, rect, timestamp);
      }
      context.restore();

      setFillColor(context, Colors.LIGHTER_GRAY);
      setStrokeColor(context, Colors.LIGHTGREY);
      context.lineWidth = 2 * window.devicePixelRatio;
      context.fillRect(0.0, 0.0, queueWidth, rect.height);
      context.strokeRect(0.0, 0.0, queueWidth, rect.height);

      // Draw lines between packet slots in queue.
      double slotWidth = queueWidth / queueSize;

      for (int i = 0; i < queueSize; i++) {
        context.beginPath();

        context.moveTo(slotWidth * i, 0.0);
        context.lineTo(slotWidth * i, rect.height);

        context.stroke();
      }

      // Draw packets in queue.
      int i = queueSize - 1;
      for (QueuePacket packet in _queue.toList(growable: false)) {
        packet.render(context, new Rectangle<double>(i * slotWidth, 0.0, slotWidth, rect.height));

        i--;
      }

      // Draw router image.
      double routerWidth = rect.width * 0.3 - padding;
      double routerRatio = Images.routerIconImage.aspectRatio;
      double routerHeight = 1 / routerRatio * routerWidth;
      double yOffset = rect.height / 2 - routerHeight / 2;

      if (router != null) {
        context.drawImageScaled(router, queueWidth + padding, yOffset, routerWidth, routerHeight); // Sender box
      }
    }

    context.restore();
  }

  /// Add item to queue. Returns a bool whether it could be added to the queue
  /// or was dropped.
  bool addToQueue({Color color = Colors.BLACK}) {
    if (_queue.length < queueSize) {
      _queue.add(new QueuePacket(color));

      return true;
    } else {
      _particleGenerator.color = color;
      _particleGenerator.start();

      return false;
    }
  }

  QueuePacket takeFromQueue() {
    return _queue.removeFirst();
  }

  bool get queueEmpty => _queue.isEmpty;

  void updateQueueLength(int newLength) {
    queueSize = newLength;

    int diff = queueSize - _queue.length;

    if (diff < 0) {
      // Queue shrank -> Remove items.
      for (int i = 0; i < diff.abs(); i++) {
        _queue.removeLast();
      }
    }
  }

  void clearQueue() {
    _queue.clear();
  }

}