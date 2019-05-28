import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_select/material_dropdown_select.dart';
import 'package:angular_components/model/selection/selection_model.dart';
import 'package:angular_components/model/ui/has_renderer.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/animations.dart';
import 'package:hm_animations/src/ui/animations/base/connector/animation_component_connector.dart';
import 'package:hm_animations/src/ui/animations/onion_router/onion_router_animation_component.template.dart' as template;
import 'package:hm_animations/src/ui/animations/onion_router/scenario/hidden_service_drawable.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/internet_service_drawable.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/viewer/drawable_viewer.dart';
import 'package:hm_animations/src/ui/misc/angular_components/selection_options.dart';

@Component(
  selector: "onion-router-animation",
  templateUrl: "onion_router_animation_component.html",
  styleUrls: ["onion_router_animation_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    DrawableViewer,
    MaterialButtonComponent,
    MaterialIconComponent,
    MaterialDropdownSelectComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class OnionRouterAnimationComponent extends AnimationComponentConnector implements OnInit, OnDestroy {
  /// Descriptor of this animation.
  static AnimationDescriptor<OnionRouterAnimationComponent> descriptor = AnimationDescriptor<OnionRouterAnimationComponent>(
    id: Animations.ID_COUNTER++,
    componentFactory: template.OnionRouterAnimationComponentNgFactory,
    baseTranslationKey: "onion-router",
    previewImagePath: "",
    // TODO
    path: "onion-router",
    version: 2,
  );

  /// Component change detector reference.
  final ChangeDetectorRef _cd;

  /// Service to get translations from.
  final I18nService _i18n;

  /// Listener getting events when the language changes.
  LanguageLoadedListener _languageLoadedListener;

  /// Selection model for scenario.
  SelectionModel<Scenario> scenarioSelectionModel;

  /// Selection options for scenario.
  SelectionOptions<Scenario> scenarioSelectionOptions;

  /// Item renderer for scenario selection options.
  ItemRenderer<Scenario> scenarioSelectionItemRenderer;

  /// Subscription to scenario selection changes.
  StreamSubscription _scenarioSelectionChanges;

  /// Current drawable to display.
  Drawable _currentDrawable;

  /// Create animation.
  OnionRouterAnimationComponent(
    this._cd,
    this._i18n,
  );

  @override
  void ngOnInit() {
    _initTranslations();
    _initScenarioDropDown();
  }

  @override
  ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
    _scenarioSelectionChanges.cancel();
  }

  @override
  AnimationDescriptor get animationDescriptor => OnionRouterAnimationComponent.descriptor;

  @override
  String get credits => _i18n.get("${animationDescriptor.baseTranslationKey}.credits").toString();

  @override
  Drawable get drawable => _currentDrawable;

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
      InternetServiceDrawable(),
      HiddenServiceDrawable(),
    ]);
    scenarioSelectionModel = SelectionModel.single(selected: scenarioSelectionOptions.optionsList.first, keyProvider: (scenario) => scenario.id);
    scenarioSelectionItemRenderer = (dynamic scenario) => scenario.toString();

    _scenarioSelectionChanges = scenarioSelectionModel.selectionChanges.listen((changes) {
      if (scenarioSelectionModel.selectedValues.isNotEmpty) {
        _currentDrawable = scenarioSelectionModel.selectedValues.first as Drawable;
      }
    });
    if (scenarioSelectionModel.selectedValues.isNotEmpty) {
      _currentDrawable = scenarioSelectionModel.selectedValues.first as Drawable;
    }
  }

  String get scenarioSelectionLabel => scenarioSelectionModel.selectedValues.isNotEmpty ? scenarioSelectionModel.selectedValues.first.name : "";

  void test() {
    (scenarioSelectionModel.selectedValues.first as InternetServiceDrawable).start(true);
  }

  // Find a new route in the onion router network.
  void reroute() {
    (scenarioSelectionModel.selectedValues.first as InternetServiceDrawable).reroute();
  }
}
