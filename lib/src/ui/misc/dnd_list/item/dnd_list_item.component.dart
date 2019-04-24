import 'dart:html';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/ui/misc/dnd_list/renderer/list_item_renderer.dart';

/// Component showing an drag and drop list item.
@Component(
  selector: "dnd-list-item",
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: "dnd_list_item.component.html",
  styleUrls: ["dnd_list_item.component.css"],
  encapsulation: ViewEncapsulation.None,
)
class DnDListItemComponent<T> {
  /// Container where to inject the item renderer.
  @ViewChild("container", read: ViewContainerRef)
  ViewContainerRef container;

  /// Loader to resolve the correct Angular component.
  final ComponentLoader _componentLoader;

  /// The HTML element of the component.
  final Element element;

  /// Factory of the item renderer component.
  ComponentFactory<ListItemRenderer<T>> _itemRenderer;

  /// The currently shown renderer instance.
  ListItemRenderer<T> _currentRenderer;

  /// Item to show using the item renderer.
  T _item;

  /// Create item instance.
  DnDListItemComponent(this._componentLoader, this.element);

  /// Set the correct item renderer to display the item with.
  @Input()
  void set itemRenderer(ComponentFactory<ListItemRenderer<T>> factory) {
    if (factory != _itemRenderer) {
      _itemRenderer = factory;

      _currentRenderer = _componentLoader.loadNextToLocation(_itemRenderer, container).instance;

      if (_item != null) {
        _currentRenderer.setItem(_item);
      }
    }
  }

  /// Set the item to show.
  @Input()
  void set item(T value) {
    _item = value;

    if (_currentRenderer != null) {
      _currentRenderer.setItem(_item);
    }
  }
}
