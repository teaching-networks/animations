import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/di.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_select/material_dropdown_select.dart';
import 'package:angular_components/model/selection/selection_model.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_ui.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/misc/angular_components/selection_options.dart';
import 'package:hm_animations/src/ui/misc/description/description.component.dart';
import 'package:hm_animations/src/util/size.dart';

typedef String ItemRenderer<T>(T t);

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
    MaterialDropdownSelectComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class OnionRouterAnimation extends CanvasAnimation with AnimationUI implements OnInit, OnDestroy {
  /// Aspect ratio of the host icon.
  static const double _hostIconAspectRatio = 232.28 / 142.6;

  /// Aspect ratio of the router icon.
  static const double _routerIconAspectRatio = 536.1 / 221.3;

  /// Component change detector reference.
  final ChangeDetectorRef _cd;

  /// Service to get translations from.
  final I18nService _i18n;

  /// Listener getting events when the language changes.
  LanguageLoadedListener _languageLoadedListener;

  /// Whether to repaint the canvas next render cycle.
  bool _repaint = true;

  /// Icon of a host computer.
  ImageElement _hostIcon = ImageElement(src: "img/animation/host_icon.svg");

  /// Icon of a router.
  ImageElement _routerIcon = ImageElement(src: "img/animation/router.svg");

  /// Selection model for scenario.
  SelectionModel<Scenario> scenarioSelectionModel;

  /// Selection options for scenario.
  SelectionOptions<Scenario> scenarioSelectionOptions;

  /// Item renderer for scenario selection options.
  ItemRenderer<Scenario> scenarioSelectionItemRenderer;

  /// Subscription to scenario selection changes.
  StreamSubscription _scenarioSelectionChanges;

  /// Create animation.
  OnionRouterAnimation(
    this._cd,
    this._i18n,
  );

  @override
  void ngOnInit() {
    _initTranslations();
    _initImages();
    _initScenarioDropDown();
  }

  /// Initialize translations.
  void _initTranslations() {
    _languageLoadedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);
  }

  /// Initialize images.
  void _initImages() {
    Future.wait([
      _hostIcon.onLoad.first,
      _routerIcon.onLoad.first,
    ]).then((_) {
      _invalidate();
    });
  }

  /// Initialize the scenario dropdown selection.
  void _initScenarioDropDown() {
    scenarioSelectionOptions = SelectionOptions([
      Scenario(id: 1, name: "Dienst im Internet geroutet"),
      Scenario(id: 2, name: "Versteckter Dienst"),
    ]);
    scenarioSelectionModel = SelectionModel.single(selected: scenarioSelectionOptions.optionsList.first, keyProvider: (scenario) => scenario.id);
    scenarioSelectionItemRenderer = (dynamic scenario) => scenario.toString();

    _scenarioSelectionChanges = scenarioSelectionModel.selectionChanges.listen((changes) {
      _invalidate();
    });
  }

  @override
  ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
    _scenarioSelectionChanges.cancel();
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

    _drawImageOnCanvas(_hostIcon, aspectRatio: _hostIconAspectRatio, width: 100.0);
    _drawImageOnCanvas(_routerIcon, aspectRatio: _routerIconAspectRatio, width: 100.0, y: 100);
  }

  /// Draw image of the canvas.
  void _drawImageOnCanvas(
    CanvasImageSource src, {
    double x = 0,
    double y = 0,
    double width,
    double height,
    double aspectRatio = 1.0,
  }) {
    double w = 0;
    double h = 0;
    if (width != null && height != null) {
      w = width;
      h = height;
    } else if (width != null) {
      w = width;
      h = width / aspectRatio;
    } else if (height != null) {
      h = height;
      w = height * aspectRatio;
    }

    context.drawImageToRect(src, Rectangle<double>(x, y, w, h));
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

  String get scenarioSelectionLabel => scenarioSelectionModel.selectedValues.isNotEmpty ? scenarioSelectionModel.selectedValues.first.name : "";

  int get canvasHeight => 500;

  void test() {
    _invalidate();
  }
}
