/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/services/storage_service/storage_service.dart';
import 'package:hm_animations/src/util/str/message.dart';
import "package:intl/intl_browser.dart";

typedef void LanguageLoadedListener(String newLocale);

/**
 * I18n service is a service where you can fetch translations for a specific locale.
 */
@Injectable()
class I18nService {
  /**
   * Key in local storage where the current locale to use can be stored.
   */
  static const String LOCAL_STORAGE_LOCALE = "locale";

  /**
   * List of available languages. For each language a file with the locale abbreviation (e. g. "de", "en") as name has to be available on the server.
   */
  static const List<Language> AVAILABLE_LANGUAGES = const [const Language("en", "English"), const Language("de", "Deutsch")];

  /**
   * Default locale, in case the browsers locale could not be fetched.
   */
  static const String DEFAULT_LOCALE = "en";

  /**
   * URL where the translation files lie.
   */
  static const String URL = "i18n/";

  /**
   * File ending of the translation files.
   */
  static const String FILE_ENDING = ".json";

  /**
   * Currently set locale.
   */
  String _currentLocale;

  /**
   * Key to message lookup.
   */
  Map<String, IdMessage<String>> _lookup = new Map<String, IdMessage<String>>();

  /**
   * Used to get the base url of the application.
   */
  final PlatformLocation _platformLocation;

  /// Storage service to store things locally.
  final StorageService _storage;

  /**
   * List of listeners which want to be notified when the language has been loaded (or changed).
   */
  List<LanguageLoadedListener> _languageLoadedListener;

  /// List of completer which await completion when a language has been loaded.
  List<Completer> _fetchCompleter = [];

  /**
   * I18n Service constructor.
   */
  I18nService(this._platformLocation, this._storage) {
    // Start locale file lookup.
    getLocale().then((locale) {
      _currentLocale = locale;

      _reload();
    });
  }

  /**
   * Reload language file.
   * @param notifyListener whether to notify the langauge changed listeners that the language has changed
   */
  void _reload() {
    _loadLangFile(_currentLocale).then((jsonMap) {
      _initLookup(jsonMap);
      _notifyLanguageLoaded(_currentLocale);
    });
  }

  /**
   * Load language file with the passed locale.
   */
  Future<dynamic> _loadLangFile(String locale) async {
    if (!_hasLocale(locale)) {
      locale = DEFAULT_LOCALE;
    }

    return HttpRequest.getString(_platformLocation.getBaseHrefFromDOM() + URL + locale + FILE_ENDING).then((value) {
      try {
        return json.decode(value);
      } catch (e) {
        print("Language resource file could not be loaded for locale: $locale");
      }
    });
  }

  /**
   * Initialize key to message lookup.
   */
  void _initLookup(dynamic jsonMap) {
    Map<String, String> map = (jsonMap as Map).cast<String, String>();

    for (String key in map.keys) {
      IdMessage<String> msg = _lookup[key];

      if (msg == null) {
        msg = new IdMessage<String>(identifier: key, value: map[key]);
        _lookup[key] = msg;
      } else {
        msg.value = map[key];
      }
    }
  }

  /**
   * Get translated message for the passed key.
   */
  IdMessage<String> get(String key) {
    IdMessage<String> msg = _lookup[key];

    if (msg == null) {
      // Create new message to be filled later (or not if not translated yet).
      msg = new IdMessage<String>.empty(identifier: key);
      _lookup[key] = msg;
    }

    return msg;
  }

  /// Get translated messsage for the passed key and return a
  /// future of when the message if fully loaded.
  Future<IdMessage<String>> getAsync(String key) async {
    IdMessage<String> msg = get(key);

    if (msg.value.isEmpty) {
      // Wait until message is loaded
      final completer = Completer();
      _fetchCompleter.add(completer);
      await completer.future;

      if (msg.value.isEmpty) {
        throw Exception("the requested Message is still empty, even after loading a locale language file");
      }

      return msg;
    } else {
      return msg;
    }
  }

  /**
   * Get the current locale.
   */
  String getCurrentLocale() {
    return _currentLocale;
  }

  /**
   * Get the default locale.
   */
  String getDefaultLocale() {
    return DEFAULT_LOCALE;
  }

  /**
   * Set the locale (Causes a reload of the language file).
   */
  void setLocale(String locale) {
    if (locale != getCurrentLocale() && _hasLocale(locale)) {
      _storage.set(LOCAL_STORAGE_LOCALE, locale);
      _currentLocale = locale;

      _reload();
    }
  }

  /**
   * Get locale.
   */
  Future<String> getLocale() async {
    String l = _storage.get(LOCAL_STORAGE_LOCALE);

    if (l == null) {
      return findSystemLocale().then((locale) {
        if (locale != null && locale.length >= 2) {
          locale = locale.substring(0, 2); // We only need the first two letters.
        }

        if (!_hasLocale(locale)) {
          locale = DEFAULT_LOCALE;
        }

        return locale;
      });
    } else {
      return l;
    }
  }

  /**
   * Get languages available.
   */
  List<Language> getLanguages() {
    return AVAILABLE_LANGUAGES;
  }

  /**
   * Clear locale in local storage.
   */
  void clearLocale() {
    _storage.remove(LOCAL_STORAGE_LOCALE);
  }

  /**
   * Check if locale is available for translations.
   */
  bool _hasLocale(String locale) {
    for (Language lang in AVAILABLE_LANGUAGES) {
      if (lang.locale == locale) {
        return true;
      }
    }

    return false;
  }

  /**
   * Add a listener which should be notified when a language has been loaded.
   */
  void addLanguageLoadedListener(LanguageLoadedListener listener) {
    if (_languageLoadedListener == null) {
      _languageLoadedListener = List<LanguageLoadedListener>();
    }

    _languageLoadedListener.add(listener);
  }

  /**
   * Remove a listener which should be notified when the language loaded.
   * Returns whether the listener could be removed.
   */
  bool removeLanguageLoadedListener(LanguageLoadedListener listener) {
    if (_languageLoadedListener != null) {
      return _languageLoadedListener.remove(listener);
    }

    return false;
  }

  /**
   * Notify all language changed listeners that the language has been loaded.
   */
  void _notifyLanguageLoaded(String newLocale) {
    if (_languageLoadedListener != null) {
      for (LanguageLoadedListener listener in _languageLoadedListener) {
        listener.call(newLocale);
      }
    }

    if (_fetchCompleter != null && _fetchCompleter.isNotEmpty) {
      for (Completer c in _fetchCompleter) {
        if (!c.isCompleted) {
          c.complete();
        }
      }

      _fetchCompleter.clear();
    }
  }
}

/**
 * Language for translations.
 */
class Language {
  /**
   * Locale abbreviation (e. g. "de" or "en").
   */
  final String locale;

  /**
   * Name of the language.
   */
  final String name;

  /**
   * Create new language.
   */
  const Language(this.locale, this.name);

  /**
   * Get path to the languages flag image.
   */
  String get flagImagePath => "img/languages/$locale.svg";

  @override
  String toString() {
    return name;
  }
}
