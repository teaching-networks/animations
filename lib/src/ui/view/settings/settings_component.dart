/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/routes.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/services/settings_service/model/setting.dart';
import 'package:hm_animations/src/services/settings_service/settings_service.dart';
import 'package:hm_animations/src/util/str/message.dart';

/// Component used to manage settings.
@Component(
  selector: "settings-component",
  templateUrl: "settings_component.html",
  styleUrls: ["settings_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    MaterialToggleComponent,
  ],
  pipes: [I18nPipe],
)
class SettingsComponent implements OnInit, OnDestroy {
  /// Default settings
  static const Map<String, dynamic> defaultSettings = {
    "carousel.enabled": true,
  };

  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Service managing settings.
  final SettingsService _settingsService;

  /// Service to get authentication details from.
  final AuthenticationService _authenticationService;

  /// Router to navigate within the app.
  final Router _router;

  /// Available routes in the app.
  final Routes _routes;

  /// Service to get translations from.
  final I18nService _i18n;

  /// Subscription to login events.
  StreamSubscription<bool> _loggedInSub;

  /// Available settings.
  Map<String, dynamic> _settings;

  /// Whether settings have been loaded.
  bool isBusy = false;

  /// Listener notified when the language changes.
  LanguageLoadedListener _languageLoadedListener;

  IdMessage<String> _carouselEnableMsg;

  /// Create component.
  SettingsComponent(
    this._cd,
    this._settingsService,
    this._authenticationService,
    this._router,
    this._routes,
    this._i18n,
  );

  @override
  void ngOnInit() {
    if (!_authenticationService.isLoggedIn) {
      _router.navigateByUrl("/"); // Redirect to start page because user cannot see group management.
    }

    _loggedInSub = _authenticationService.loggedIn.listen((loggedIn) {
      if (!loggedIn) {
        // If logged out while on group management page.
        _router.navigate(_routes.groups.path);
      }
    });

    _languageLoadedListener = (_) => _cd.markForCheck();
    _i18n.addLanguageLoadedListener(_languageLoadedListener);

    _carouselEnableMsg = _i18n.get("settings.carousel.enable");

    _loadSettings();
  }

  @override
  void ngOnDestroy() {
    _loggedInSub.cancel();
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
  }

  String get carouselEnableMsg => _carouselEnableMsg.toString();

  /// Load the application settings.
  Future<void> _loadSettings() async {
    isBusy = true;
    _cd.markForCheck();

    List<Setting<dynamic>> result = await _settingsService.readAll();
    Map<String, dynamic> map = Map<String, dynamic>();
    for (final s in result) {
      map[s.key] = s.value;
    }
    _settings = map;

    isBusy = false;
    _cd.markForCheck();
  }

  /// Check whether the setting with the passed [key] is available.
  bool hasSetting(String key) => _settings != null && _settings[key] != null;

  /// Get saved setting or default value.
  T getOrDefault<T>(String key) {
    if (hasSetting(key)) {
      return _settings[key];
    } else {
      return defaultSettings[key];
    }
  }

  /// Change a bool setting.
  Future<void> boolSettingChange(String key, bool value) async {
    isBusy = true;
    _cd.markForCheck();

    if (hasSetting(key)) {
      final success = await _settingsService.update(Setting<bool>.from(key, value));
      if (success) {
        _settings[key] = value;
      }
    } else {
      final res = await _settingsService.create<bool>(Setting<bool>.from(key, value));
      if (res != null) {
        _settings[key] = value;
      }
    }

    isBusy = false;
    _cd.markForCheck();
  }
}
