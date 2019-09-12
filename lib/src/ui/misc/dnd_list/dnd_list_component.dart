/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:dnd/dnd.dart';
import 'package:hm_animations/src/ui/misc/dnd_list/item/dnd_list_item.component.dart';
import 'package:hm_animations/src/ui/misc/dnd_list/renderer/default/default_item_renderer.component.dart';
import 'package:hm_animations/src/ui/misc/dnd_list/renderer/default/default_item_renderer.component.template.dart' as defaultItemRenderer;
import 'package:hm_animations/src/ui/misc/dnd_list/renderer/list_item_renderer.dart';

/// Drag and drop list.
@Component(
  selector: "dnd-list",
  templateUrl: "dnd_list_component.html",
  styleUrls: ["dnd_list_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    DnDListItemComponent,
  ],
)
class DnDListComponent<T> implements AfterViewInit, AfterViewChecked, OnDestroy {
  /// The default component factory to use in case no item renderer is defined.
  static ComponentFactory<DefaultItemRendererComponent> _defaultItemRenderer = defaultItemRenderer.DefaultItemRendererComponentNgFactory;

  /// Change detection reference.
  final ChangeDetectorRef _cd;

  /// Items to display.
  List<T> _items;

  /// Renderer for each item.
  ComponentFactory<ListItemRenderer<T>> _itemRenderer;

  /// All sortable item elements..
  @ViewChildren(DnDListItemComponent)
  List<DnDListItemComponent> sortableItems;

  /// The current draggable listener.
  Draggable _currentDraggable;

  /// The current dropzone listener.
  Dropzone _currentDropzone;

  /// Whether to reinitialize drag and drop the next view refresh.
  bool _reinitializeDragAndDrop = false;

  /// Create drag and drop list.
  DnDListComponent(this._cd);

  @override
  void ngAfterViewInit() {
    _bindDragAndDrop();
  }

  @override
  void ngAfterViewChecked() {
    if (_reinitializeDragAndDrop) {
      _unbindDragAndDrop();
      _bindDragAndDrop();
    }
  }

  @override
  void ngOnDestroy() {
    _unbindDragAndDrop();
  }

  /// Set items to display in the list.
  @Input()
  void set items(List<T> value) {
    _items = value;
    _reinitializeDragAndDrop = true;
    _cd.markForCheck();
  }

  /// Get all items to display in the list.
  List<T> get items => _items;

  /// Get the item factory to use as item renderer.
  ComponentFactory<ListItemRenderer<T>> get itemRenderer => _itemRenderer != null ? _itemRenderer : _defaultItemRenderer;

  /// Set the item factory to use as item renderer.
  @Input()
  void set itemRenderer(ComponentFactory<ListItemRenderer<T>> value) {
    _itemRenderer = value;
  }

  /// Bind drag and drop listeners on the sortable elements.
  void _bindDragAndDrop() {
    if (sortableItems == null) {
      throw Exception("Failed to bind drag and drop to items");
    }

    final elements = sortableItems.map((comp) => comp.element).toList();

    _currentDraggable = Draggable(
      elements,
      verticalOnly: true,
      avatarHandler: AvatarHandler.clone(),
    );

    _currentDropzone = Dropzone(
      elements,
    );

    _currentDropzone.onDrop.listen((DropzoneEvent event) {
      swapItems(
        int.tryParse(event.draggableElement.attributes["data-index"]),
        int.tryParse(event.dropzoneElement.attributes["data-index"]),
      );
    });

    _reinitializeDragAndDrop = false;
  }

  /// Unbind drag and drop listeners from all sortable elements.
  void _unbindDragAndDrop() {
    if (_currentDraggable != null) {
      _currentDraggable.destroy();
      _currentDraggable = null;
    }

    if (_currentDropzone != null) {
      _currentDropzone.destroy();
      _currentDropzone = null;
    }
  }

  /// Swap the two items in the items list.
  void swapItems(int index1, int index2) {
    if (index1 == null || index2 == null) {
      throw Exception("Failed to swap items via drag and drop");
    }

    final tmp = _items[index1];
    _items[index1] = _items[index2];
    _items[index2] = tmp;

    _cd.markForCheck();
  }
}
