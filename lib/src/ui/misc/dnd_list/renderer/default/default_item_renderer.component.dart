import 'dart:html';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/ui/misc/dnd_list/renderer/list_item_renderer.dart';

@Component(
  selector: "default-dnd-list-item-renderer-component",
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: """
  <li class='dnd-list-item'>
    {{ name }}
  </li>
  """,
  encapsulation: ViewEncapsulation.None,
)
class DefaultItemRendererComponent implements ListItemRenderer<dynamic> {
  final ChangeDetectorRef _cd;

  final Element element;

  Object _backingObject;

  DefaultItemRendererComponent(this._cd, this.element);

  @override
  void setItem(item) {
    _backingObject = item;
    _cd.markForCheck();
  }

  String get name => _backingObject.toString();
}
