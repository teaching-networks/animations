import 'dart:async';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';

/// Structural directive showing content only if user is logged in.
@Directive(selector: "[restricted]")
class RestrictedDirective implements OnInit, OnDestroy {

  final TemplateRef _templateRef;
  final ViewContainerRef _viewContainer;

  final AuthenticationService _authService;
  StreamSubscription<bool> _loginSub;

  RestrictedDirective(this._templateRef, this._viewContainer, this._authService);

  @override
  void ngOnInit() {
    _updateView(_authService.isLoggedIn);

    _loginSub = _authService.loggedIn.listen((loggedIn) {
      _updateView(loggedIn);
    });
  }

  @override
  void ngOnDestroy() {
    _loginSub.cancel();
  }

  void _updateView(bool showView) {
    if (showView) {
      _viewContainer.createEmbeddedView(_templateRef);
    } else {
      _viewContainer.clear();
    }
  }

}