import 'package:angular/angular.dart';
import 'package:angular/di.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_ui.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/misc/description/description.component.dart';
import 'package:hm_animations/src/util/size.dart';

@Component(
  selector: "onion-router-animation",
  templateUrl: "onion_router_animation.html",
  styleUrls: ["onion_router_animation.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    CanvasComponent,
    DescriptionComponent,
    MaterialButtonComponent,
    MaterialIconComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class OnionRouterAnimation extends CanvasAnimation with AnimationUI implements OnInit, OnDestroy {
  /// Component change detector reference.
  final ChangeDetectorRef _cd;

  /// Service to get translations from.
  final I18nService _i18n;

  /// Listener getting events when the language changes.
  LanguageLoadedListener _languageLoadedListener;

  /// Whether to repaint the canvas next render cycle.
  bool _repaint = true;

  /// Create animation.
  OnionRouterAnimation(
    this._cd,
    this._i18n,
  );

  @override
  void ngOnInit() {
    _languageLoadedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);
  }

  @override
  ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);

    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    if (!_repaint) {
      return;
    }
    _repaint = false;

    context.clearRect(0, 0, size.width, size.height);
    context.fillText(timestamp.toString(), 100, 100);
  }

  @override
  void onCanvasResize(Size newSize) {
    super.onCanvasResize(newSize);

    _invalidate();
  }

  /// Invalidate the canvas.
  void _invalidate() {
    _repaint = true;
  }

  int get canvasHeight => 500;

  void test() {
    _invalidate();
  }
}
