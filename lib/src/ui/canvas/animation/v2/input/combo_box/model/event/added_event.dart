/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/combo_box_model_event.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/combo_box_model_event_types.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/item/combo_box_item.dart';

/// Event emitted when items have been added to the model.
class AddedEvent implements ComboBoxModelEvent {
  /// List of added items.
  final List<ComboBoxItem> addedItems;

  /// Create event.
  AddedEvent({
    this.addedItems,
  });

  @override
  ComboBoxModelEventType get type => ComboBoxModelEventType.ADDED;
}
