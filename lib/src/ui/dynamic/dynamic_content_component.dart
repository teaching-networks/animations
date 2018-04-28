import 'package:angular/angular.dart';

/**
 * Component
 */
@Component(
  selector: "dynamic-content",
  templateUrl: "dynamic_content_component.html",
  styleUrls: const ["dynamic_content_component.css"]
)
class DynamicContentComponent {

  @ViewChild("placeholder", read: ViewContainerRef)
  ViewContainerRef placeholder;

  /**
   * Resolver resolves components.
   */
  final ComponentLoader _componentLoader;

  /**
   * Create new dynamic content component instance.
   */
  DynamicContentComponent(this._componentLoader);

  /**
   * Called when the component to show changes.
   */
  @Input("componentToShow")
  void set showComponent(dynamic factory) {
    _componentLoader.loadNextToLocation(factory, placeholder);
  }

}