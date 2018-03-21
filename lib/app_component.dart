import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:netzwerke_animationen/src/animations/dummy/dummy_animation.dart';
import 'package:netzwerke_animationen/src/canvas/canvas_component.dart';

@Component(
  selector: 'net-app',
  styleUrls: const ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: const [materialDirectives, CanvasComponent, DummyAnimation],
  providers: const [materialProviders],
)
class AppComponent {

}
