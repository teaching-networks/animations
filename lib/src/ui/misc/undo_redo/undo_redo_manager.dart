/// Manager for undoing / redoing stuff.
abstract class UndoRedoManager {
  /// Undo a step.
  void undo();

  /// Redo a step.
  void redo();
}
