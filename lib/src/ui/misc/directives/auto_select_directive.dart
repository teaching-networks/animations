import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/laminate/components/modal/modal.dart';
import 'package:angular_components/laminate/popup/popup.dart';
import 'package:angular_components/utils/browser/dom_service/dom_service.dart';
import 'package:angular_components/utils/disposer/disposer.dart';

/// The underlying text elements text will be selected as soon as directive is initialized.
@Directive(
  selector: '[autoSelect]',
)
class AutoSelectDirective implements OnInit, OnDestroy {
  final _disposer = Disposer.oneShot();

  bool _autoSelect;

  /// Node which contains a input text field to select.
  HtmlElement _node;

  DomService _domService;
  ModalComponent _modal;
  PopupRef _popupRef;

  AutoSelectDirective(
    this._node,
    this._domService,
    @Optional() this._modal,
    @Optional() this._popupRef,
  );

  @override
  void ngOnInit() {
    if (!_autoSelect) {
      return;
    }

    if (_modal != null || _popupRef != null) {
      bool isVisible = _popupRef != null ? _popupRef.isVisible : _modal.resolvedOverlayRef.isVisible;
      _onModalOrPopupVisibleChanged(isVisible);

      Stream<bool> onVisibleChanged = _popupRef != null ? _popupRef.onVisibleChanged : _modal.resolvedOverlayRef.onVisibleChanged;
      _disposer.addStreamSubscription(onVisibleChanged.listen(_onModalOrPopupVisibleChanged));
    } else {
      _domService.scheduleWrite(selectText);
    }
  }

  /// Enables the auto select directive.
  /// This value should not change during the component's life.
  @Input()
  set autoSelect(bool value) {
    _autoSelect = value;
  }

  /// Select text in the underlying text field if any.
  void selectText() {
    if (!_autoSelect) {
      return;
    }

    if (_node != null) {
      final field = _node.querySelector("input");
      if (field != null && field is TextInputElement) {
        field.select();
      }
    }
  }

  /// Callback in case the element is within a popup or modal which changed its visibility.
  void _onModalOrPopupVisibleChanged(bool isVisible) {
    if (isVisible) {
      _domService.scheduleWrite(selectText);
    }
  }

  @override
  void ngOnDestroy() {
    _disposer.dispose();

    _node = null;
    _domService = null;
    _modal = null;
    _popupRef = null;
  }
}
