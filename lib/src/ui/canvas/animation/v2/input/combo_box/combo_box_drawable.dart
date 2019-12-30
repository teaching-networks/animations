/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/container/container.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/container/round_rect/round_rect_container.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/container/round_rect/round_rect_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/horizontal_layout.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/separator/vertical_separator_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/drawable/select_combo_box_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/combo_box_model_event.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/combo_box_model_event_types.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/event/removed_event.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/model/listener/combo_box_model_change_listener.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/combo_box/style/combo_box_style.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

import 'model/abstract_combo_box_model.dart';

/// Drawable realizing a combo box list input component.
class ComboBoxDrawable extends Drawable {
  /// Style of the combo box list drawable.
  final ComboBoxStyle style;

  /// Model of the list drawable.
  final AbstractComboBoxModel model;

  /// State of the combo box.
  _ComboBoxState _state;

  /// Listener listening for model changes.
  ComboBoxModelChangeListener _modelChangeListener;

  /// Drawable showing the label of the currently selected item.
  TextDrawable _labelDrawable;

  /// Container holding the selected item label.
  Container _labelContainer;

  /// Create drawable.
  ComboBoxDrawable({
    Drawable parent,
    this.style = const ComboBoxStyle(),
    this.model,
    bool disabled = false,
  })  : _state = _ComboBoxState(disabled: disabled),
        super(parent: parent) {
    _init();
  }

  /// Check whether the drawable is currently disabled.
  void get disabled => _state.disabled;

  /// Set the disabled state of the drawable.
  void set disabled(bool value) {
    if (value != _state.disabled) {
      _state.disabled = value;
      invalidate();
    }
  }

  /// Initialize the drawable.
  void _init() {
    assert(model != null);

    _modelChangeListener = (event) => _onModelChange(event);
    model.addChangeListener(_modelChangeListener);

    _labelContainer = RoundRectContainer(
      parent: this,
      child: HorizontalLayout(
        children: [
          SelectComboBoxDrawable(
            color: Colors.SLATE_GREY,
            orientation: SelectArrowOrientation.LEFT,
            callBack: () {
              final itemList = model.items.toList();
              int currentIndex = itemList.indexOf(model.selected);

              if (currentIndex > 0) {
                model.select(model.get(currentIndex - 1));
              }
            },
          ),
          VerticalSeparatorDrawable(xPadding: 4),
          _labelDrawable = TextDrawable(
            text: "Select...",
            color: style.unselectedLabelColor,
            lineHeight: 1.0,
          ),
          VerticalSeparatorDrawable(xPadding: 4),
          SelectComboBoxDrawable(
            color: Colors.SLATE_GREY,
            orientation: SelectArrowOrientation.RIGHT,
            callBack: () {
              final itemList = model.items.toList();
              int currentIndex = itemList.indexOf(model.selected);

              if (currentIndex + 1 < itemList.length) {
                model.select(model.get(currentIndex + 1));
              }
            },
          ),
        ],
      ),
      style: RoundRectStyle(
        edges: Edges.all(2),
        borderColor: Colors.LIGHTGREY,
        fillColor: Colors.LIGHTER_GRAY,
        borderThickness: 2,
        padding: style.itemPadding,
      ),
    );

    _recalculateSize();
  }

  /// Recalculate the drawable size.
  void _recalculateSize() {
    setSize(
      width: _labelContainer.size.width,
      height: _labelContainer.size.height,
    );
  }

  /// What should happen when the model changes.
  void _onModelChange(ComboBoxModelEvent event) {
    switch (event.type) {
      case ComboBoxModelEventType.REMOVED:
        if (model.hasSelected) {
          final selected = model.selected;

          RemovedEvent re = event as RemovedEvent;
          if (re.removedItems.contains(selected)) {
            model.select(null);
            invalidate();
          }
        }
        break;
      case ComboBoxModelEventType.SELECTED:
        _onSelectionChanged(true);
        break;
      case ComboBoxModelEventType.UNSELECTED:
        _onSelectionChanged(false);
        break;
      default:
        break;
    }
  }

  /// Called when the selection is changed.
  void _onSelectionChanged(bool isSelect) {
    if (isSelect) {
      _labelDrawable.text = model.selected.label;
    } else {
      _labelDrawable.text = "Select...";
    }

    _recalculateSize();
  }

  @override
  void cleanup() {
    model.removeChangeListener(_modelChangeListener);

    super.cleanup();
  }

  @override
  void draw() {
    _labelContainer.render(ctx, lastPassTimestamp);
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update.
  }

  @override
  void onMouseDown(CanvasMouseEvent event) {
    if (containsPos(event.pos)) {
      if (!_state.active) {
        _state.active = true;
        invalidate();
      }
    }
  }
}

/// State of the combo box.
class _ComboBoxState {
  /// Whether the combo box is hovered.
  bool hovered;

  /// Whether the current mouse down started on the box.
  bool active;

  /// Whether the combo box is disabled.
  bool disabled;

  /// Create state.
  _ComboBoxState({
    this.hovered = false,
    this.active = false,
    this.disabled = false,
  });
}
