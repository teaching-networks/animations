/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/abstract_combo_box_model.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/added_event.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/combo_box_model_event.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/removed_event.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/select_event.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/unselect_event.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/item/combo_box_item.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/listener/combo_box_model_change_listener.dart';

/// Description of a combo box model.
class SimpleComboBoxModel<T> implements AbstractComboBoxModel<T> {
  /// Items of the model.
  final List<ComboBoxItem<T>> items;

  /// List of change listeners listening to combo box model events.
  Set<ComboBoxModelChangeListener> _changeListener = {};

  /// The currently selected item.
  ComboBoxItem<T> _selected;

  /// Create model.
  SimpleComboBoxModel({
    List<ComboBoxItem<T>> items,
  }) : this.items = items == null ? [] : items;

  @override
  void add(ComboBoxItem<T> item) {
    items.add(item);

    _notifyChangeListener(AddedEvent(addedItems: [item]));
  }

  @override
  void addAll(Iterable<ComboBoxItem<T>> toAdd) {
    items.addAll(toAdd);

    _notifyChangeListener(AddedEvent(addedItems: List.of(toAdd)));
  }

  @override
  void clear() {
    items.clear();

    _notifyChangeListener(RemovedEvent(removedItems: List.of(items)));
  }

  @override
  ComboBoxItem<T> get(int index) {
    return items[index];
  }

  @override
  void remove(ComboBoxItem<T> item) {
    items.remove(item);

    _notifyChangeListener(RemovedEvent(removedItems: [item]));
  }

  @override
  void select(ComboBoxItem item) {
    if (item != null) {
      _selected = item;
      _notifyChangeListener(SelectEvent());
    } else {
      _selected = null;
      _notifyChangeListener(UnselectEvent());
    }
  }

  @override
  bool get hasSelected => _selected != null;

  @override
  ComboBoxItem<T> get selected => _selected;

  @override
  void addChangeListener(ComboBoxModelChangeListener listener) {
    _changeListener.add(listener);
  }

  @override
  void removeChangeListener(ComboBoxModelChangeListener listener) {
    _changeListener.remove(listener);
  }

  /// Notify all change listeners that the passed [event] occurred.
  void _notifyChangeListener(ComboBoxModelEvent event) {
    for (final l in _changeListener) {
      l(event);
    }
  }
}
