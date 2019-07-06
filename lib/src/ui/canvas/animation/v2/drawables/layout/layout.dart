import 'dart:async';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';

/// Layout laying multiple drawable out.
abstract class Layout extends Drawable {
  /// Subscription to size changes of the parent drawable.
  StreamSubscription<SizeChange> _sizeChangeStreamSubscription;

  /// Subscriptions to size changes of the child drawables.
  List<StreamSubscription<SizeChange>> _childSizeChangeStreamSubscriptions;

  /// Create layout.
  Layout(Drawable parent) : super(parent) {
    if (parent != null) {
      throw Exception("A layout needs to have a parent specified (To calculate the correct size from). Null values are not allowed!");
    }

    _init();
  }

  /// Initialize the layout.
  void _init() {
    List<Drawable> c = children;

    if (c == null || c.isEmpty) {
      throw Exception("A layout cannot lay out no children. Please specify at least one child drawable.");
    }

    parent.sizeChanges.listen(onParentSizeChange);

    _childSizeChangeStreamSubscriptions = List<StreamSubscription<SizeChange>>();
    for (Drawable child in children) {
      _childSizeChangeStreamSubscriptions.add(child.sizeChanges.listen(onChildSizeChange));
      addDependentDrawable(child);
    }
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Layouts normally do not need to update anything.
  }

  @override
  void draw() {
    layout();
  }

  @override
  void cleanup() {
    if (_sizeChangeStreamSubscription != null) {
      _sizeChangeStreamSubscription.cancel();
    }

    if (_childSizeChangeStreamSubscriptions != null) {
      for (final sub in _childSizeChangeStreamSubscriptions) {
        sub.cancel();
      }
    }

    super.cleanup();
  }

  /// Get all child drawables of the layout.
  List<Drawable> get children;

  /// What should happen when the size of the parent drawable changes.
  void onParentSizeChange(SizeChange change);

  /// What should happen when the size of a child drawable changes.
  void onChildSizeChange(SizeChange change);

  /// Layout the drawables. Same as the call to draw().
  void layout();
}
