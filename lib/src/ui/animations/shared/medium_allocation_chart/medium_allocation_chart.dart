import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/shared/medium_allocation_chart/change_marker.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/canvas_pausable.dart';
import 'package:meta/meta.dart';

/// Chart visualizing a mediums allocation in time.
class MediumAllocationChart extends CanvasDrawable with CanvasPausableMixin {
  /// Default duration to display on the charts range.
  static const Duration _defaultDurationToDisplay = Duration(seconds: 25);

  /// Offset between value and state bars.
  static const double _valueStateOffset = 5.0;

  /// Duration to display on the charts range.
  final Duration durationToDisplay;

  /// Id of the chart.
  final String id;

  /// Label of the value bar.
  final Message valueBarLabel;

  /// Label of the status bar.
  final Message statusBarLabel;

  /// State changes over time.
  List<ChangeMarker<Color>> _stateChanges = List<ChangeMarker<Color>>();

  /// Value changes over time.
  List<ChangeMarker<Color>> _valueChanges = List<ChangeMarker<Color>>();

  /// Timestamp of the last rendering cycle.
  num _lastRenderTimestamp;

  /// Create medium allocation chart.
  MediumAllocationChart({
    @required this.id,
    @required this.valueBarLabel,
    @required this.statusBarLabel,
    this.durationToDisplay = _defaultDurationToDisplay,
  });

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    if (isPaused && _lastRenderTimestamp != null) {
      timestamp = _lastRenderTimestamp;
    }

    context.save();

    context.translate(rect.left, rect.top);

    double height = rect.height;
    double width = rect.width;

    int duration = durationToDisplay.inMilliseconds;
    num minTimestamp = timestamp - duration;

    _cleanOldChanges(minTimestamp);

    context.save();

    double barWidth = width * 0.8;
    double barOffset = width - barWidth;

    double barHeight = height * 0.7;
    _drawChanges(context, _valueChanges, timestamp, duration, barOffset, barHeight, barWidth);
    _drawLabel(context, id == null ? valueBarLabel.toString() : "${valueBarLabel.toString()} $id", barOffset, barHeight);

    context.translate(0.0, barHeight + _valueStateOffset);
    barHeight = height * 0.3 - _valueStateOffset;
    _drawChanges(context, _stateChanges, timestamp, duration, barOffset, barHeight, barWidth);
    _drawLabel(context, statusBarLabel.toString(), barOffset, barHeight);

    context.restore();

    // Render border
    setStrokeColor(context, Colors.DARK_GRAY);
    context.lineWidth = window.devicePixelRatio;
    context.strokeRect(barOffset, 0.0, barWidth, height);

    context.restore();

    _lastRenderTimestamp = timestamp;
  }

  /// Draw label for the bar.
  void _drawLabel(CanvasRenderingContext2D context, String label, double width, double height) {
    context.textAlign = "right";
    context.textBaseline = "middle";

    setFillColor(context, Colors.DARK_GRAY);
    context.fillText(label, width - 10.0, height / 2);
  }

  /// Draw changes list.
  void _drawChanges(
      CanvasRenderingContext2D context, List<ChangeMarker<Color>> changes, num timestamp, int duration, double xOffset, double height, double width) {
    double lastX = 0.0;
    for (ChangeMarker<Color> marker in changes.reversed) {
      double relativeX = getRelativeXPosForTimestamp(marker.timestamp, timestamp, duration);
      double x = width * relativeX;

      setFillColor(context, marker.change);
      context.fillRect(lastX + xOffset, 0.0, x - lastX, height);

      lastX = x;
    }
  }

  /// Get the relative x position (Value in range [0.0, 1.0]) of the passed [timestamp] in the range from [minTimestamp] to [minTimestamp] + duration.
  double getRelativeXPosForTimestamp(num timestamp, num minTimestamp, num duration) {
    num diff = minTimestamp - timestamp;

    return min(diff / duration, 1.0);
  }

  /// Set the current state color.
  setStateColor(Color color) {
    if (_stateChanges.isNotEmpty && _stateChanges.last.change == color) {
      // The change would be nonsense -> Ignore it.
      return;
    }

    num timestamp = isPaused ? _lastRenderTimestamp : window.performance.now();

    _stateChanges.add(ChangeMarker<Color>(
      change: color,
      timestamp: timestamp,
    ));
  }

  /// Set the current value color.
  setValueColor(Color color) {
    if (_valueChanges.isNotEmpty && _valueChanges.last.change == color) {
      // The change would be nonsense -> Ignore it.
      return;
    }

    num timestamp = isPaused ? _lastRenderTimestamp : window.performance.now();

    _valueChanges.add(ChangeMarker<Color>(
      change: color,
      timestamp: timestamp,
    ));
  }

  /// Clean all old changes older than [minTimestamp].
  void _cleanOldChanges(num minTimestamp) {
    _cleanOldChangesInList(minTimestamp, _stateChanges);
    _cleanOldChangesInList(minTimestamp, _valueChanges);
  }

  /// Clean all old changes older then [minTimestamp] in the passed [markers] list.
  void _cleanOldChangesInList<T>(num minTimestamp, List<ChangeMarker<T>> markers) {
    List<int> toRemove = List<int>();

    for (int i = markers.length - 1; i >= 0; i--) {
      ChangeMarker<T> marker = markers[i];

      if (marker.timestamp < minTimestamp) {
        toRemove.add(i);
      } else {
        break;
      }
    }

    if (toRemove.length > 1) {
      /// Remove all but the last one out of range.
      for (int index in toRemove.sublist(1)) {
        markers.removeAt(index);
      }
    }
  }

  @override
  void switchPauseSubAnimations() {
    // Do nothing as there are no sub animations.
  }

  @override
  void unpaused(num timestampDifference) {
    // Update change markers to use new timestamp.
    _valueChanges = _updateMarkerTimestamp(_valueChanges, timestampDifference);
    _stateChanges = _updateMarkerTimestamp(_stateChanges, timestampDifference);
  }

  /// Update the passed change markers by adding the passed [addToTimestamp] on top of each markers timestamp.
  List<ChangeMarker<Color>> _updateMarkerTimestamp(List<ChangeMarker<Color>> changeMarkers, num addToTimestamp) {
    List<ChangeMarker<Color>> newChangeMarkers = new List<ChangeMarker<Color>>();

    for (ChangeMarker<Color> marker in changeMarkers) {
      newChangeMarkers.add(ChangeMarker<Color>(
        timestamp: marker.timestamp + addToTimestamp,
        change: marker.change,
      ));
    }

    return newChangeMarkers;
  }
}
