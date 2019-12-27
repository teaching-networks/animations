/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/item/combo_box_item.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/listener/combo_box_model_change_listener.dart';

/// Abstract description of the capabilities of a combo box model.
abstract class AbstractComboBoxModel<T> {
  /// Select the passed item.
  void select(ComboBoxItem<T> item);

  /// Whether the model has a selected item.
  bool get hasSelected;

  /// Get the currently selected combo box item or null.
  ComboBoxItem<T> get selected;

  /// Items in the model.
  Iterable<ComboBoxItem<T>> get items;

  /// Add an item to the model.
  void add(ComboBoxItem<T> item);

  /// Add multiple items to the model.
  void addAll(Iterable<ComboBoxItem<T>> toAdd);

  /// Remove an item from the model.
  void remove(ComboBoxItem<T> item);

  /// Get an item by its index.
  ComboBoxItem<T> get(int index);

  /// Clear all items from the model.
  void clear();

  /// Add a change listener to the model.
  void addChangeListener(ComboBoxModelChangeListener listener);

  /// Remove a change listener from the model.
  void removeChangeListener(ComboBoxModelChangeListener listener);
}
