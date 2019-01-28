import 'package:hm_animations/src/ui/misc/undo_redo/undo_redo_manager.dart';
import 'package:hm_animations/src/ui/misc/undo_redo/undo_redo_step.dart';

/// Simple undo redo manager implementation.
class SimpleUndoRedoManager implements UndoRedoManager {
  /// Default limit of undoable steps.
  static const int _defaultLimit = 50;

  /// Limit of undoable / redoable steps.
  final int limit;

  /// List of undoable / redoable steps.
  List<UndoRedoStep> _steps = List<UndoRedoStep>();

  /// Position in the undoable step list.
  int _position;

  /// Create undo redo manager.
  SimpleUndoRedoManager({
    this.limit,
  });

  /// Add an undoable to the manager.
  void addUndoable(UndoRedoStep step) {
    _steps.add(step);
  }

  @override
  void redo() {
    if (!canRedo()) {
      return;
    }

    UndoRedoStep redoable = _steps[++_position];
    redoable.undo();
  }

  @override
  void undo() {
    if (!canUndo()) {
      return;
    }

    UndoRedoStep undoable = _steps[--_position];
    undoable.undo();
  }

  /// Whether an undo is possible.
  bool canUndo() => _steps.isNotEmpty && _position > 0;

  /// Whether an redo is possible.
  bool canRedo() => _steps.isNotEmpty && _steps.length > _position + 1;
}
