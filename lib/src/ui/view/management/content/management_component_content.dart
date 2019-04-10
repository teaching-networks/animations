/// Content components shown in the Management Component need to implement this class.
abstract class ManagementComponentContent<T> {
  /// Set the entity to show.
  void setEntity(T entity);

  /// When a deletion is requested.
  /// Return whether it was successful.
  Future<bool> onDelete();

  /// When a save is requested.
  /// Return the saved entity whether it was successful.
  Future<T> onSave();
}
