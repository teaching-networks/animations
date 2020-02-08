/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:hm_animations/src/ui/view/carousel/item/carousel_item.component.dart';
import 'package:hm_animations/src/ui/view/carousel/service/carousel.service.dart';
import 'package:hm_animations/src/ui/view/carousel/visualizer/carousel_item_visualizier.dart';
import 'package:hm_animations/src/util/size.dart';

/// The carousel component is displaying arbitrary items of a list horizontally
/// while one item is always in focus. Buttons are used to switch to the next or previous
/// item of the list.
@Component(
  selector: "carousel-component",
  styleUrls: ["carousel.component.css"],
  templateUrl: "carousel.component.html",
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    CarouselItemComponent,
    MaterialButtonComponent,
    MaterialIconComponent,
  ],
  providers: [
    CarouselService,
  ],
)
class CarouselComponent<T> implements OnInit, OnDestroy, AfterViewInit {
  /// Change detector of the component.
  final ChangeDetectorRef _cd;

  /// Service used to communicate with the root carousel component (this).
  final CarouselService _carouselService;

  /// Component factory for the carousel items.
  ComponentFactory<CarouselItemVisualizer<T>> _itemComponentFactory;

  /// Items to display in the carousel.
  Iterable<T> _items;

  /// Height of the element.
  @HostBinding("style.height.px")
  int height = 0;

  /// Subscription to item size changes.
  StreamSubscription<ItemSizeChange> _itemSizeStreamSub;

  /// Subscription to selected item changes.
  StreamSubscription<ItemSelectedChange> _selectedStreamSub;

  /// Currently selected item.
  int _selected = 0;

  /// Create component.
  CarouselComponent(
    this._cd,
    this._carouselService,
  );

  /// Set the items to display in the carousel.
  @Input()
  void set items(Iterable<T> value) {
    _items = value;
    height = 0; // Reset height
    _cd.markForCheck();
  }

  /// Get the items to display in the carousel.
  Iterable<T> get items => _items;

  /// Set the component factory for the carousel items.
  @Input()
  void set itemComponentFactory(ComponentFactory<CarouselItemVisualizer<T>> value) {
    _itemComponentFactory = value;
    _cd.markForCheck();
  }

  /// Get the items component factory.
  ComponentFactory<CarouselItemVisualizer<T>> get itemComponentFactory => _itemComponentFactory;

  @override
  void ngOnInit() {
    _itemSizeStreamSub = _carouselService.itemSizeStream.listen((change) {
      if (change.size.height > height) {
        height = change.size.height;
        _cd.markForCheck();
      }
    });

    _selectedStreamSub = _carouselService.selectedStream.listen((change) {
      _selected = change.index;
    });
  }

  @override
  void ngOnDestroy() {
    if (_itemSizeStreamSub != null) {
      _itemSizeStreamSub.cancel();
    }

    if (_selectedStreamSub != null) {
      _selectedStreamSub.cancel();
    }
  }

  @override
  void ngAfterViewInit() {
    _carouselService.select(items.first, 0);
  }

  /// Select the next item.
  void next() {
    if (_selected == items.length - 1) {
      _carouselService.select(items.first, 0);
    } else {
      _carouselService.select(items.toList()[_selected + 1], _selected + 1);
    }
  }

  /// Select the previous item.
  void prev() {
    if (_selected == 0) {
      _carouselService.select(items.last, items.length - 1);
    } else {
      _carouselService.select(items.toList()[_selected - 1], _selected - 1);
    }
  }
}
