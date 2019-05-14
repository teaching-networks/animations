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
import 'package:hm_animations/src/ui/animations/onion_router/animation_controller.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/hidden_service.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/internet_service.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
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
class OnionRouterAnimation extends CanvasAnimation with AnimationUI implements OnInit, OnDestroy, AnimationController {
  /// Component change detector reference.
  final ChangeDetectorRef _cd;

  /// Service to get translations from.
  final I18nService _i18n;

  /// Listener getting events when the language changes.
  LanguageLoadedListener _languageLoadedListener;

  /// Whether to repaint the canvas next render cycle.
  bool _repaint = true;

  /// Selection model for scenario.
  SelectionModel<Scenario> scenarioSelectionModel;

  /// Selection options for scenario.
  SelectionOptions<Scenario> scenarioSelectionOptions;

  /// Item renderer for scenario selection options.
  ItemRenderer<Scenario> scenarioSelectionItemRenderer;

  /// Subscription to scenario selection changes.
  StreamSubscription _scenarioSelectionChanges;

  BuildInfo _buildInfo = BuildInfo(rebuild: true);

  /// Create animation.
  OnionRouterAnimation(
    this._cd,
    this._i18n,
  );

  @override
  void ngOnInit() {
    _initTranslations();
    _initScenarioDropDown();
  }

  /// Initialize translations.
  void _initTranslations() {
    _languageLoadedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);
  }

  /// Initialize the scenario dropdown selection.
  void _initScenarioDropDown() {
    scenarioSelectionOptions = SelectionOptions([
      InternetService(this),
      HiddenService(this),
    ]);
    scenarioSelectionModel = SelectionModel.single(selected: scenarioSelectionOptions.optionsList.first, keyProvider: (scenario) => scenario.id);
    scenarioSelectionItemRenderer = (dynamic scenario) => scenario.toString();

    _scenarioSelectionChanges = scenarioSelectionModel.selectionChanges.listen((changes) {
      invalidate();
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

    if (getBuildInfo().rebuild) {
      context.clearRect(0, 0, size.width, size.height);
    }

    if (scenarioSelectionModel.selectedValues.isNotEmpty) {
      final selectedScenario = scenarioSelectionModel.selectedValues.first;

      if (selectedScenario is CanvasDrawable) {
        (selectedScenario as CanvasDrawable).render(context, Rectangle<double>(0.0, 0.0, size.width, size.height), timestamp);
      }
    }

    _buildInfo.reset();
  }

  @override
  void onCanvasResize(Size newSize) {
    super.onCanvasResize(newSize);

    invalidate();
  }

  /// Invalidate the canvas.
  BuildInfo invalidate() {
    _repaint = true;

    return getBuildInfo();
  }

  String get scenarioSelectionLabel => scenarioSelectionModel.selectedValues.isNotEmpty ? scenarioSelectionModel.selectedValues.first.name : "";

  int get canvasHeight => 500;

  void test() {
    invalidate()..rebuild = false;
  }

  @override
  BuildInfo getBuildInfo() => _buildInfo;
}
