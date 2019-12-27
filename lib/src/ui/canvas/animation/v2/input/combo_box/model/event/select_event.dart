/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/combo_box_model_event.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/combo_box_model_event_types.dart';

/// Event emitted when an item gets selected.
class SelectEvent implements ComboBoxModelEvent {
  @override
  ComboBoxModelEventType get type => ComboBoxModelEventType.SELECTED;
}
