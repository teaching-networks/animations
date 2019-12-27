/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/combo_box_model_event_types.dart';

/// Event of the combo box model.
abstract class ComboBoxModelEvent {
  /// Get the type of the event.
  ComboBoxModelEventType get type;
}
