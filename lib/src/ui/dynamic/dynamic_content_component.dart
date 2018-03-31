import 'package:angular/angular.dart';
import 'package:netzwerke_animationen/src/ui/dynamic/dynamic_content_directive.dart';

/**
 * Component
 */
@Component(
  selector: "dynamic-content",
  templateUrl: "dynamic_content_component.html",
  styleUrls: const ["dynamic_content_component.css"],
  directives: const [DynamicContentDirective]
)
class DynamicContentComponent {

  @ViewChild(DynamicContentDirective)
  DynamicContentDirective host;

  /**
   * Resolver resolves components.
   */
  ComponentResolver _componentResolver;

  /**
   * Create new dynamic content component instance.
   */
  DynamicContentComponent(this._componentResolver);

  /**
   * Called when the component to show changes.
   */
  @Input("componentToShow")
  void set showComponent(Type compType) {
    print("WDjqwdw");
    host.viewContainerRef.clear();

    ComponentFactory compFactory = _componentResolver.resolveComponentSync(compType);
    host.viewContainerRef.createComponent(compFactory);
  }

}