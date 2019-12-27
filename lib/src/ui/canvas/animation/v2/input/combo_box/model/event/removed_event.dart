/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/combo_box_model_event.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/combo_box_model_event_types.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/item/combo_box_item.dart';

/// Event emitted when items are removed from the model.
class RemovedEvent implements ComboBoxModelEvent {
  /// The removed items from the model.
  final List<ComboBoxItem> removedItems;

  /// Create removed event.
  RemovedEvent({
    this.removedItems,
  });

  @override
  ComboBoxModelEventType get type => ComboBoxModelEventType.REMOVED;
}
