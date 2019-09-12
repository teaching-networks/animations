/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

/// Manager for undoing / redoing stuff.
abstract class UndoRedoManager {
  /// Undo a step.
  void undo();

  /// Redo a step.
  void redo();
}
