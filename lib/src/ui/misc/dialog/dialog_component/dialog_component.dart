/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/misc/dialog/instance/dialog_instance.dart';

/// Component which can be opened as dialog by the dialog service.
abstract class DialogComponent<R, T, D> {
  /// Instance of this dialog.
  DialogInstance<dynamic, T, D> instance;

  /// Set the dialog instance this component is showing.
  void setInstance(DialogInstance<dynamic, T, D> value) {
    if (instance != null) {
      throw Exception("Instance should only be set once");
    }

    instance = value;
  }
}
