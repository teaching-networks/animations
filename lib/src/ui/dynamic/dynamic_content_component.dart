import 'package:angular/angular.dart';

/// Component showing arbitrary angular components.
@Component(
  selector: "dynamic-content",
  templateUrl: "dynamic_content_component.html",
  styleUrls: ["dynamic_content_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class DynamicContentComponent<T> {
  /// Container where to inject the angular component.
  @ViewChild("placeholder", read: ViewContainerRef)
  ViewContainerRef placeholder;

  /// Loader to resolve the correct Angular component.
  final ComponentLoader _componentLoader;

  /// Factory of the component to display.
  ComponentFactory<T> _componentFactory;

  /// Instance of the currently loaded component.
  T _loadedComponent;

  /// Create dynamic content instance.
  DynamicContentComponent(this._componentLoader);

  /// Show the passed component.
  @Input()
  void set componentFactory(ComponentFactory<T> factory) {
    if (factory != _componentFactory) {
      _componentFactory = factory;

      // Load component.
      _loadedComponent = _componentLoader.loadNextToLocation(_componentFactory, placeholder).instance;
    }
  }

  /// Get the currently loaded component.
  T get loadedComponent => _loadedComponent;
}
