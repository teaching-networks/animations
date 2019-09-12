/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

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
  int _position = 0;

  /// Create undo redo manager.
  SimpleUndoRedoManager({
    this.limit = _defaultLimit,
  });

  /// Add an undoable to the manager.
  void addStep(UndoRedoStep step) {
    int trim = 0;
    if (_position > limit - 1) {
      trim = _position - (limit - 1);
    }

    _steps = _steps.getRange(trim, _position).toList();
    _position -= trim;

    _steps.add(step);

    _position++;
  }

  @override
  void redo() {
    if (!canRedo()) {
      return;
    }

    UndoRedoStep step = _steps[_position++];
    step.redo();
  }

  @override
  void undo() {
    if (!canUndo()) {
      return;
    }

    UndoRedoStep step = _steps[--_position];
    step.undo();
  }

  /// Clear all undos and redos.
  void clear() {
    _steps.clear();
    _position = 0;
  }

  /// Whether an undo is possible.
  bool canUndo() => _steps.isNotEmpty && _position > 0;

  /// Whether an redo is possible.
  bool canRedo() => _steps.isNotEmpty && _steps.length > _position;
}
