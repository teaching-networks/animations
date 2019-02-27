import 'package:meta/meta.dart';

/// Marks a change at a given time.
class ChangeMarker<T> {
  /// Timestamp of the change.
  final num timestamp;

  /// [value] of the change.
  final T change;

  /// Create a change in time.
  ChangeMarker({
    @required this.timestamp,
    @required this.change,
  });
}
