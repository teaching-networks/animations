/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';

/// Component showing arbitrary angular components.
@Component(
  selector: "dynamic-content",
  templateUrl: "dynamic_content_component.html",
  styleUrls: ["dynamic_content_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class DynamicContentComponent<T> implements OnDestroy {
  /// Container where to inject the angular component.
  @ViewChild("placeholder", read: ViewContainerRef)
  ViewContainerRef placeholder;

  /// Loader to resolve the correct Angular component.
  final ComponentLoader _componentLoader;

  /// Factory of the component to display.
  ComponentFactory<T> _componentFactory;

  /// Instance of the currently loaded component.
  T _loadedComponent;

  /// Stream controller emitting events once the component has been loaded.
  StreamController<T> _compLoadedStreamController = StreamController<T>(sync: false);

  /// Create dynamic content instance.
  DynamicContentComponent(this._componentLoader);

  @override
  void ngOnDestroy() {
    _compLoadedStreamController.close();
  }

  /// Show the passed component.
  @Input()
  void set componentFactory(ComponentFactory<T> factory) {
    if (factory != _componentFactory) {
      _componentFactory = factory;

      // Load component.
      _loadedComponent = _componentLoader.loadNextToLocation(_componentFactory, placeholder).instance;

      if (_loadedComponent != null) {
        _compLoadedStreamController.add(_loadedComponent);
      }
    }
  }

  /// Get the currently loaded component.
  T get loadedComponent => _loadedComponent;

  /// Register to this stream to get notified about loaded components.
  @Output()
  Stream<T> get loaded => _compLoadedStreamController.stream;
}
