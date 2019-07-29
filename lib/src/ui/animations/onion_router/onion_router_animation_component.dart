import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_select/material_dropdown_select.dart';
import 'package:angular_components/material_slider/material_slider.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:angular_components/model/selection/selection_model.dart';
import 'package:angular_components/model/ui/has_renderer.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/animations.dart';
import 'package:hm_animations/src/ui/animations/base/connector/animation_component_connector.dart';
import 'package:hm_animations/src/ui/animations/onion_router/onion_router_animation_component.template.dart' as template;
import 'package:hm_animations/src/ui/animations/onion_router/scenario/controls_component.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/hidden_service/controls/hidden_service_controls_component.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/hidden_service/hidden_service_drawable.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/internet_service/controls/internet_service_controls_component.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/internet_service/internet_service_drawable.dart';
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
    MaterialSliderComponent,
    MaterialToggleComponent,
    HiddenServiceControlsComponent,
    InternetServiceControlsComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class OnionRouterAnimationComponent extends AnimationComponentConnector implements OnInit, OnDestroy, AfterViewInit {
  /// Descriptor of this animation.
  static AnimationDescriptor<OnionRouterAnimationComponent> descriptor = AnimationDescriptor<OnionRouterAnimationComponent>(
    id: Animations.ID_COUNTER++,
    componentFactory: template.OnionRouterAnimationComponentNgFactory,
    baseTranslationKey: "onion-router",
    previewImagePath: "img/animation/preview/onion-router-preview.png",
    path: "onion-router",
    version: 2,
  );

  /// Component change detector reference.
  final ChangeDetectorRef _cd;

  /// Service to get translations from.
  final I18nService _i18n;

  /// Loader to resolve an Angular component.
  final ComponentLoader _componentLoader;

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

  @ViewChild("controlContainer", read: ViewContainerRef)
  ViewContainerRef controlContainer;

  /// Create animation.
  OnionRouterAnimationComponent(
    this._cd,
    this._i18n,
    this._componentLoader,
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
  void ngAfterViewInit() {
    if (scenarioSelectionModel != null && scenarioSelectionModel.selectedValues.isNotEmpty) {
      _loadControlsComponentForScenario(scenarioSelectionModel.selectedValues.first);
    }
  }

  /// Load the controls component of the passed [scenario] into the controls view.
  void _loadControlsComponentForScenario(Scenario scenario) {
    if (scenario == null) {
      throw Exception("Cannot load controls component from null scenario");
    }

    if (controlContainer == null) {
      throw Exception("Cannot load controls component into null view");
    }

    controlContainer.clear();

    ControlsComponent controlsComponent = _componentLoader
        .loadNextToLocation(
          scenario.controlComponentFactory,
          controlContainer,
        )
        .instance;

    controlsComponent.scenario = scenario;
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
      InternetServiceDrawable(_i18n.get("onion-router.routed-service"), _i18n),
      HiddenServiceDrawable(_i18n.get("onion-router.hidden-service"), _i18n),
    ]);
    scenarioSelectionModel = SelectionModel.single(selected: scenarioSelectionOptions.optionsList.first, keyProvider: (scenario) => scenario.id);
    scenarioSelectionItemRenderer = (dynamic scenario) => scenario.toString();

    _scenarioSelectionChanges = scenarioSelectionModel.selectionChanges.listen((changes) {
      if (scenarioSelectionModel.selectedValues.isNotEmpty) {
        _currentDrawable = scenarioSelectionModel.selectedValues.first as Drawable;
        _loadControlsComponentForScenario(scenarioSelectionModel.selectedValues.first);
      }
    });
    if (scenarioSelectionModel.selectedValues.isNotEmpty) {
      _currentDrawable = scenarioSelectionModel.selectedValues.first as Drawable;
    }
  }

  String get scenarioSelectionLabel => scenarioSelectionModel.selectedValues.isNotEmpty ? scenarioSelectionModel.selectedValues.first.name : "";
}
