import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_components/material_tab/fixed_material_tab_strip.dart';
import 'package:angular_components/material_tab/tab_change_event.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:markdown/markdown.dart';

/// Text editor with markdown support and preview.
@Component(
  selector: "editor-component",
  templateUrl: "editor.component.html",
  styleUrls: ["editor.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    materialInputDirectives,
    FixedMaterialTabStripComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class EditorComponent implements OnInit, OnDestroy {
  /// The default maximum character count.
  static const int _defaultMaxCount = 500;

  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Where to get translations from.
  final I18nService _i18n;

  /// The currently selected tab index.
  int _tabIndex = 0;

  /// The text to edit / show.
  String _text = "";

  /// The maximum count of characters to allow.
  int _maxCount = _defaultMaxCount;

  /// Label to show for the editor.
  String _label = "";

  /// Generated HTML for the preview.
  String previewHTML = "";

  /// Listener getting notified whenever the language changes.
  LanguageLoadedListener _languageLoadedListener;

  Message _previewLabel;
  Message _editLabel;

  /// Stream controller emitting text changes.
  StreamController<String> _textChangedController = StreamController<String>.broadcast(sync: false);

  /// Create component.
  EditorComponent(
    this._cd,
    this._i18n,
  );

  @override
  void ngOnInit() {
    _languageLoadedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);

    _initTranslations();
  }

  /// Load all needed translations.
  void _initTranslations() {
    _editLabel = _i18n.get("editor.edit");
    _previewLabel = _i18n.get("editor.preview");
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
    _textChangedController.close();
  }

  /// What to do if the tab changes.
  void onTabChange(TabChangeEvent event) {
    _tabIndex = event.newIndex;

    if (_tabIndex == 1) {
      // Preview tab -> regenerate preview HTML
      _refreshPreview();
    }
  }

  /// Refresh the preview.
  void _refreshPreview() {
    if (text == null) {
      previewHTML = "";
      return;
    }

    previewHTML = markdownToHtml(
      text,
      inlineSyntaxes: [new InlineHtmlSyntax()],
    );
  }

  /// Labels of the tabs.
  List<String> get tabLabels => [
        _editLabel.toString(),
        _previewLabel.toString(),
      ];

  /// The currently selected tab index.
  int get tabIndex => _tabIndex;

  /// What to do if the text changes.
  void onTextChange(String newText) {
    _text = newText;

    _textChangedController.add(newText);
  }

  /// Get the text to edit / show.
  String get text => _text;

  /// Set the text to display.
  @Input("text")
  void set text(String value) {
    _text = value;

    _refreshPreview();

    _cd.markForCheck();
  }

  /// Get text changes as stream.
  @Output("textChange")
  Stream<String> get textChanges => _textChangedController.stream;

  /// Get the maximum amount of characters allowed.
  int get maxCount => _maxCount;

  /// Set the maximum amount of characters allowed.
  @Input()
  set maxCount(int value) {
    _maxCount = value;
  }

  /// Get the label to show for the editor.
  String get label => _label;

  /// Set the label to show for the editor.
  @Input()
  set label(String value) {
    _label = value;
  }
}
