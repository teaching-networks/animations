import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/misc/editor/editor.component.dart';
import 'package:hm_animations/src/ui/view/management/content/management_component_content.dart';

/// Component displaying animation info.
@Component(
  selector: "animation-management-content-component",
  templateUrl: "animation_management_content.component.html",
  styleUrls: ["animation_management_content.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    EditorComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class AnimationManagementContentComponent implements ManagementComponentContent<AnimationDescriptor<dynamic>>, OnInit, OnDestroy {
  /// Maximum characters a description is allowed to have.
  static const int _maxDescriptionLength = 10000;

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

  /// Properties to edit.
  Map<String, String> _properties;

  /// The description to show / edit.
  String description;

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

      _load();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);
  }

  /// Load contents.
  Future<void> _load() async {
    if (_animationDescriptor == null) {
      return;
    }

    _properties = await _animationService.getProperties(_animationDescriptor.id);
    if (_properties != null) {
      if (_properties["description"] == null) {
        // Load from translations instead
        description = _i18n.get("${_animationDescriptor.baseTranslationKey}.description").toString();
      } else {
        description = _properties["description"];
      }
    } else {
      // Load from translations instead
      description = _i18n.get("${_animationDescriptor.baseTranslationKey}.description").toString();
    }

    _cd.markForCheck();
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
  }

  @override
  Future<bool> onDelete() async {
    throw Exception("Deletion not supported");
  }

  @override
  Future<AnimationDescriptor<dynamic>> onSave() async {
    bool success = true;

    // Save description
    if (description != null) {
      success = await _animationService.setProperty(_animationDescriptor.id, "description", description) && success;
    }

    return success ? _animationDescriptor : null;
  }

  @override
  void setEntity(AnimationDescriptor<dynamic> entity) async {
    _animationDescriptor = entity;

    await _load();

    _cd.markForCheck();
  }

  /// Get the current animation descriptor to show.
  AnimationDescriptor<dynamic> get animationDescriptor => _animationDescriptor;

  /// The maximum description character length.
  int get maxDescriptionLength => _maxDescriptionLength;
}
