/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:hm_animations/src/ui/view/carousel/service/carousel.service.dart';
import 'package:hm_animations/src/ui/view/carousel/visualizer/carousel_item_visualizier.dart';

/// Component displaying an item of the carousel component.
@Component(
  selector: "carousel-item-component",
  templateUrl: "carousel_item.component.html",
  styleUrls: ["carousel_item.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
  ],
)
class CarouselItemComponent<T> implements OnInit, AfterViewInit, OnDestroy {
  /// Change detector of the component.
  final ChangeDetectorRef _cd;

  /// Loader for angular components.
  final ComponentLoader _componentLoader;

  /// Service used to communicate with the root component.
  final CarouselService _carouselService;

  /// Item to display.
  T _item;

  /// Component factory of the component to display the item with.
  ComponentFactory<CarouselItemVisualizer<T>> _componentFactory;

  /// Container to create the item component in.
  @ViewChild("container", read: ViewContainerRef)
  ViewContainerRef viewRef;

  /// Whether the view is ready to load another component in.
  bool _viewReady = false;

  /// Currently loaded visualizer.
  CarouselItemVisualizer<T> _visualizer;

  /// Subscription to the selected item changes.
  StreamSubscription _selectedItemSub;

  /// Whether the item is currently selected.
  @HostBinding("class.selected")
  bool selected = false;

  /// Whether the item is currently neighbor of the selected.
  @HostBinding("class.neighbor")
  bool neighbor = false;

  /// Offset of the item.
  @HostBinding("style.left.%")
  int offset = 0;

  /// Index of the item.
  int _index;

  /// Create component.
  CarouselItemComponent(
    this._cd,
    this._componentLoader,
    this._carouselService,
  );

  /// Set the item to display.
  @Input()
  void set item(T value) {
    _item = value;

    if (_visualizer != null) {
      _visualizer.item = value;
    }
  }

  /// Get the item to display.
  T get item => _item;

  /// Set the component factory of the component to display the item with.
  @Input()
  void set componentFactory(ComponentFactory<CarouselItemVisualizer<T>> value) {
    _componentFactory = value;

    if (_viewReady) {
      _loadComponentInView(_componentFactory, viewRef);
    }
  }

  /// Get the component factory of the component to display the item with.
  ComponentFactory<CarouselItemVisualizer<T>> get componentFactory => _componentFactory;

  @Input()
  void set index(int value) {
    _index = value;
  }

  @override
  void ngAfterViewInit() {
    _viewReady = true;

    if (_componentFactory != null) {
      _loadComponentInView(_componentFactory, viewRef);
    }
  }

  /// Load a component produced with the passed [factory] in the passed [viewRef].
  void _loadComponentInView(ComponentFactory<CarouselItemVisualizer<T>> factory, ViewContainerRef viewRef) {
    if (viewRef.length > 0) {
      viewRef.clear(); // Whether there is already a component loaded in the view -> clear it
    }

    _visualizer = _componentLoader.loadNextToLocation(_componentFactory, viewRef).instance;
    _visualizer.item = item;
  }

  @override
  void ngOnInit() {
    _selectedItemSub = _carouselService.selectedStream.listen((change) {
      bool isSelected = change.item == item;
      bool isNeighbor = (change.index - _index).abs() == 1;

      if (selected != isSelected) {
        selected = isSelected;
        offset = 0;
      }

      if (isNeighbor != neighbor) {
        neighbor = isNeighbor;

        if (isNeighbor) {
          int c = change.index - _index;

          if (c == 1) {
            offset = -30;
          } else {
            offset = 30;
          }
        }
      }

      if (!isNeighbor && !isSelected) {
        if (_index < change.index) {
          offset = -100;
        } else {
          offset = 100;
        }
      }

      _cd.markForCheck();
    });
  }

  @override
  void ngOnDestroy() {
    if (_selectedItemSub != null) {
      _selectedItemSub.cancel();
    }
  }
}
