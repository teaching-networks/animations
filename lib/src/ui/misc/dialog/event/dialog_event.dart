/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/misc/dialog/instance/dialog_instance.dart';

/// Event emitted by the dialog service.
/// Used to show a dialog.
class DialogEvent {
  /// The dialog instance to show.
  final DialogInstance instance;

  /// Create event.
  DialogEvent(this.instance);
}
