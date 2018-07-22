import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/progress/progress.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';

/// Supplier which delivers a color based on the progress.
typedef Color ColorSupplier(double progress);

/// Drawable able to represent some kind of progress.
/// Think of it like a basic progress bar.
abstract class ProgressRect extends CanvasDrawable {

  /// Progress to display the progress of.
  final Progress progress;

  /// Color supplier delivers a color based on the progress [0.0; 1.0].
  final ColorSupplier colorSupplier;

  /// Create new progress rect.
  ProgressRect(this.progress, [this.colorSupplier]);

}
