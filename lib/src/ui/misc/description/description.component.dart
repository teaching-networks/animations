import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/animation_property.dart';
import 'package:markdown/markdown.dart';

/// Component displaying an animations description.
@Component(
  selector: "description-component",
  templateUrl: "description.component.html",
  styleUrls: ["description.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
  ],
)
class DescriptionComponent implements OnInit, OnDestroy {
  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Where to get translations from.
  final I18nService _i18n;

  /// Service managing animations.
  final AnimationService _animationService;

  /// Descriptor of an animation to show the description for.
  AnimationDescriptor<dynamic> _descriptor;

  /// Listener notified of language change events.
  LanguageLoadedListener _languageLoadedListener;

  /// Whether description could be loaded from the animation property.
  bool _hasPropertyDescription = false;

  /// Description to display.
  String _description = "";

  /// Create component.
  DescriptionComponent(
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

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
  }

  /// Load the description of the animation descriptor.
  void _load() async {
    if (_descriptor == null) {
      return;
    }

    _description = await _animationService.getProperty(_descriptor.id, AnimationProperty.descriptionKey);

    if (_description != null) {
      _hasPropertyDescription = true;
      _description = markdownToHtml(_description, inlineSyntaxes: [InlineHtmlSyntax()]);
    } else {
      // Load from translations as a fallback.
      _description = _i18n.get("${_descriptor.baseTranslationKey}.description").toString();
    }

    _cd.markForCheck();
  }

  /// Set the animation descriptor to show the description for.
  @Input()
  set descriptor(AnimationDescriptor<dynamic> value) {
    _descriptor = value;

    _load();
  }

  /// Get the description to display.
  String get description => _description;

  /// Check if the description could be loaded from the animation properties.
  bool get hasPropertyDescription => _hasPropertyDescription;
}
