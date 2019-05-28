import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/base/connector/animation_component_connector.dart';
import 'package:hm_animations/src/ui/misc/description/description.component.dart';

/// Base component showing animations.
@Component(
  selector: "animation-base-component",
  templateUrl: "animation_base_component.html",
  styleUrls: ["animation_base_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    DescriptionComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class AnimationBaseComponent<C extends AnimationComponentConnector> implements OnInit, OnDestroy {
  /// Change detection reference.
  final ChangeDetectorRef _cd;

  /// I18n service to get translated properties from.
  final I18nService _i18n;

  /// Loader to resolve an Angular component.
  final ComponentLoader _componentLoader;

  /// Container to be filled with the animation component.
  @ViewChild("animationComponentContainer", read: ViewContainerRef)
  ViewContainerRef animationComponentContainer;

  /// Factory for the animation component.
  ComponentFactory<C> _componentFactory;

  /// The loaded animation component.
  AnimationComponentConnector _loadedComponent;

  /// Listener getting notifications whenever the language changes.
  LanguageLoadedListener _languageLoadedListener;

  /// Create component.
  AnimationBaseComponent(
    this._cd,
    this._i18n,
    this._componentLoader,
  );

  @override
  void ngOnInit() {
    _languageLoadedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
  }

  @Input()
  set componentFactory(ComponentFactory<C> value) {
    if (value != _componentFactory) {
      _componentFactory = value;

      // Load component.
      _loadedComponent = _componentLoader.loadNextToLocation(_componentFactory, animationComponentContainer).instance;

      if (_loadedComponent != null) {
        _onComponentLoaded(_loadedComponent);
      }
    }
  }

  /// What to do in case an animation component has been loaded.
  void _onComponentLoaded(AnimationComponentConnector loaded) {
    _loadedComponent = loaded;

    _cd.markForCheck();
  }

  /// Whether the animation component has been loaded.
  bool get loaded => _loadedComponent != null;

  /// Get credits to show for the currently loaded component.
  String get credits => _loadedComponent.credits;

  /// Get the animation descriptor of the currently loaded animation.
  AnimationDescriptor<dynamic> get animationDescriptor => _loadedComponent.animationDescriptor;
}
