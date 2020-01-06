/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';

/// Instance of an active dialog.
class DialogInstance<R, T, D> {
  /// Factory of the component used to create the dialog contents.
  final ComponentFactory<T> componentFactory;

  /// Event controller emitting the result once ready.
  final StreamController<R> _resultEventController = StreamController.broadcast(sync: false);

  /// Data passed to the dialog.
  final D data;

  /// Create instance.
  DialogInstance(this.componentFactory, this.data);

  /// Close the dialog.
  void close([R result]) {
    if (_resultEventController.isClosed) {
      throw Exception("Result has already been emitted");
    }

    _resultEventController.add(result);
    _resultEventController.close();
  }

  /// Get the result of the dialog.
  Future<R> result() {
    return _resultEventController.stream.first;
  }
}
