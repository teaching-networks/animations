import 'package:meta/meta.dart';

/// Marks a change at a given time.
class ChangeMarker<T> {
  /// Timestamp of the change.
  final num timestamp;

  /// [value] of the change.
  final T change;
  
  /// The timestamp of when the change finished.
  final num untilTimestamp;
  
  /// Whether to show a label displaying the time until the change finished.
  final bool showUntilLabel;

  /// Create a change in time.
  ChangeMarker({
    @required this.timestamp,
    @required this.change,
    this.untilTimestamp,
    this.showUntilLabel = false,
  });
}
