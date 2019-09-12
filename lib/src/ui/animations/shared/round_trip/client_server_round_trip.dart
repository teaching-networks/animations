/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/vertical_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/progress.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/direction.dart';

/// Round trip drawable for canvases between a client and a server.
/// The round trip progress is painted based on the passed progress: 1.0 is finished RT (Round trip), 0.0 is started RT.
class ClientServerRoundTrip extends CanvasDrawable {

  /// Progress the drawables state is based on.
  final Progress progress;

  /// Color the round trip drawable is themed with.
  final Color color;

  /// Transmission delay in RTT
  final double transmissionDelay;

  /// Vertical progress bar at the client (Shows overall progress).
  VerticalProgressBar _clientBar;

  /// Vertical progress bar at the server (Shows overall progress).
  VerticalProgressBar _serverBar;

  /// Create new round trip.
  ClientServerRoundTrip(this.progress, this.color, this.transmissionDelay) {
    _clientBar = new VerticalProgressBar(progress, Direction.NORTH, (progress) => Color.opacity(color, 0.5 + progress / 2));
    _serverBar = new VerticalProgressBar(progress, Direction.NORTH, (progress) => Color.opacity(Colors.LIGHTGREY, 0.5 + progress / 2));
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    {
      context.translate(rect.left, rect.top);

      double transmissionPart = 1.0 / (transmissionDelay + 1.0) * transmissionDelay; // Part of the progress for the transmission delay.
      double connectionPart = 1.0 - transmissionPart;

      double clientServerBarWidth = rect.width * 0.1;
      double connectionWidth = rect.width - 2 * clientServerBarWidth;
      double connectionHeight = rect.height * connectionPart / 2;
      double transmissionHeight = rect.height * transmissionPart;

      // Draw client bar.
      _clientBar.render(context, new Rectangle(0.0, 0.0, clientServerBarWidth, rect.height));

      context.translate(clientServerBarWidth, 0.0);

      double p = progress.progress;
      double halfP = min(p * (2 * (1.0 + transmissionDelay)), 1.0);

      // Set up line style.
      context.lineWidth = 2.0 * window.devicePixelRatio;
      setStrokeColor(context, color);

      // Draw first line to server.
      context.beginPath();
      context.moveTo(0.0, 0.0);
      context.lineTo(connectionWidth * halfP, connectionHeight * halfP);
      context.stroke();

      if (p > connectionPart / 2) {
        halfP = min(p * (2 * (1.0 + transmissionDelay)) - 1.0, 1.0);
        // Draw second line back to the client.
        context.beginPath();
        context.moveTo(connectionWidth, connectionHeight);
        context.lineTo(connectionWidth * (1.0 - halfP), connectionHeight + connectionHeight * halfP);
        context.stroke();

        if (p > connectionPart) {
          // Draw transmission.
          setFillColor(context, Color.opacity(color, 0.5));

          halfP = (p - connectionPart) / transmissionPart;
          context.lineTo(0.0, connectionHeight * 2 + transmissionHeight * halfP);
          context.lineTo(connectionWidth, connectionHeight + transmissionHeight * halfP);
          context.closePath();
          context.fill();
        }
      }

      context.translate(connectionWidth, 0.0);

      // Draw server bar.
      _serverBar.render(context, new Rectangle(0.0, 0.0, clientServerBarWidth, rect.height));
    }
    
    context.restore();
  }

}
