import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/view/management/content/management_component_content.dart';

/// Component displaying animation info.
@Component(
  selector: "animation-management-content-component",
  templateUrl: "animation_management_content.component.html",
  styleUrls: ["animation_management_content.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    materialInputDirectives,
  ],
  pipes: [
    I18nPipe,
  ],
)
class AnimationManagementContentComponent implements ManagementComponentContent<AnimationDescriptor<dynamic>>, OnInit, OnDestroy {
  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Where to get translations from.
  final I18nService _i18n;

  /// Service managing animations.
  final AnimationService _animationService;

  /// Listener getting notifications whenever the language changes.
  LanguageLoadedListener _languageLoadedListener;

  /// The current animation descriptor to display.
  AnimationDescriptor<dynamic> _animationDescriptor;

  /// Create component
  AnimationManagementContentComponent(
    this._cd,
    this._i18n,
    this._animationService,
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

  @override
  Future<bool> onDelete() {
    throw Exception("Deletion not supported");
  }

  @override
  Future<AnimationDescriptor<dynamic>> onSave() {
    throw Exception("Saving not supported");
  }

  @override
  void setEntity(AnimationDescriptor<dynamic> entity) {
    _animationDescriptor = entity;

    _cd.markForCheck();
  }
}
