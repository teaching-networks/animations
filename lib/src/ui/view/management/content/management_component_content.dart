/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/util/options/save_options.dart';

/// Content components shown in the Management Component need to implement this class.
abstract class ManagementComponentContent<T> {
  /// Set the entity to show.
  /// Returns what should happen with the old set entity.
  Future<SaveOption> setEntity(T entity);

  /// When a deletion is requested.
  /// Return whether it was successful.
  Future<bool> onDelete();

  /// When a save is requested.
  /// Return the saved entity whether it was successful.
  Future<T> onSave();
}
