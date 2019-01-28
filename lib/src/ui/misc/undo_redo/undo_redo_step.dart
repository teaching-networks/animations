import 'package:meta/meta.dart';

/// Step you can undo and redo.
class UndoRedoStep {
  /// Function used to undo the step.
  final Function undoFunction;

  /// Function used to redo the step.
  final Function redoFunction;

  /// Create undo/redo step.
  UndoRedoStep({
    @required this.undoFunction,
    @required this.redoFunction,
  });

  /// Undo the step.
  void undo() => undoFunction();

  /// Redo the step.
  void redo() => redoFunction();
}
