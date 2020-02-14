/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:hm_animations/src/ui/view/carousel/config/auto_spin.dart';
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

  /// Subscription to spin changes.
  StreamSubscription<SpinChange> _spinStreamSub;

  /// Currently selected item.
  int _selected = 0;

  /// The current auto spin configuration.
  AutoSpinConfig _autoSpinConfig = AutoSpinConfig();

  /// Auto spin currently in progress.
  StreamSubscription<dynamic> _onGoingAutoSpin;

  /// Whether the view is initialized.
  bool _viewInit = false;

  /// Create component.
  CarouselComponent(
    this._cd,
    this._carouselService,
  );

  /// Set whether the carousel should spin automatically.
  @Input("auto-spin")
  void set autoSpin(AutoSpinConfig value) {
    _cancelAutoSpin();
    _autoSpinConfig = value;

    if (_viewInit) {
      _autoSpinNext();
    }
  }

  /// Get the current auto spin configuration.
  AutoSpinConfig get autoSpin => _autoSpinConfig;

  /// Set the items to display in the carousel.
  @Input()
  void set items(Iterable<T> value) {
    if (_items != value) {
      _items = value;
      _cd.markForCheck();
    }
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

    _spinStreamSub = _carouselService.spinStream.listen((change) {
      if (change.next) {
        next();
      } else {
        prev();
      }
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
    _viewInit = true;
    _carouselService.select(items.first, 0);

    _autoSpinNext();
  }

  /// Cancel an auto spin in progress.
  void _cancelAutoSpin() {
    if (_onGoingAutoSpin != null) {
      _onGoingAutoSpin.cancel();
      _onGoingAutoSpin = null;
    }
  }

  /// Do the next auto spin (if enabled).
  Future<void> _autoSpinNext() async {
    _cancelAutoSpin();

    if (!_autoSpinConfig.enabled) {
      return;
    }

    _onGoingAutoSpin = Future.delayed(_autoSpinConfig.duration).asStream().listen((_) {
      next();
      _autoSpinNext();
    });
  }

  /// Select the next item.
  void next() {
    _autoSpinNext();

    if (_selected == items.length - 1) {
      _carouselService.select(items.first, 0);
    } else {
      _carouselService.select(items.toList()[_selected + 1], _selected + 1);
    }
  }

  /// Select the previous item.
  void prev() {
    _autoSpinNext();

    if (_selected == 0) {
      _carouselService.select(items.last, items.length - 1);
    } else {
      _carouselService.select(items.toList()[_selected - 1], _selected - 1);
    }
  }
}
