import 'package:hm_animations/src/util/size.dart';
import 'package:meta/meta.dart';

/// Context being shared between dependent drawables.
abstract class DrawableContext {
  /// Get the size of the root canvas.
  Size get rootSize;
}

/// Immutable context object that can safely be shared between multiple dependent drawables.
class ImmutableDrawableContext implements DrawableContext {
  /// Size of the root canvas.
  final Size _rootSize;

  /// Create unmodifiable context.
  ImmutableDrawableContext({
    @required Size rootSize,
  }) : _rootSize = rootSize;

  @override
  Size get rootSize => _rootSize;
}

/// Context object that can be modified.
class MutableDrawableContext implements DrawableContext {
  /// Size of the root canvas.
  Size _rootSize;

  /// Create context.
  MutableDrawableContext({
    Size rootSize = const Size.empty(),
  }) : _rootSize = rootSize;

  @override
  Size get rootSize => _rootSize;

  set rootSize(Size value) {
    _rootSize = value;
  }

  /// Get a immutable instance of this context.
  DrawableContext getImmutableInstance() {
    return ImmutableDrawableContext(
      rootSize: rootSize,
    );
  }
}
