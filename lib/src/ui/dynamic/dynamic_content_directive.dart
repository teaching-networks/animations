import 'package:angular/angular.dart';

/**
 * Directive to dynamically add angular components during runtime to a template.
 * Also called the "Anchor directive".
 */
@Directive(
  selector: "[dyn-content]"
)
class DynamicContentDirective {

  ViewContainerRef viewContainerRef;

  DynamicContentDirective(this.viewContainerRef);

}