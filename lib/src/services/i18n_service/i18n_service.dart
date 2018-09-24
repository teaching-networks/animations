import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/services/storage_service/storage_service.dart';
import "package:intl/intl_browser.dart";

typedef void LanguageChangedListener(String newLocale);

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
  Map<String, Message> _lookup = new Map<String, Message>();

  /**
   * Used to get the base url of the application.
   */
  final PlatformLocation _platformLocation;

  /// Storage service to store things locally.
  final StorageService _storage;

  /**
   * List of listeners which want to be notified when the language changes.
   */
  List<LanguageChangedListener> _languageChangedListener;

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
      _notifyLanguageChanged(_currentLocale);
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
      Message msg = _lookup[key];

      if (msg == null) {
        msg = new Message(key, map[key]);
        _lookup[key] = msg;
      } else {
        msg.content = map[key];
      }
    }
  }

  /**
   * Get translated message for the passed key.
   */
  Message get(String key) {
    Message msg = _lookup[key];

    if (msg == null) {
      // Create new message to be filled later (or not if not translated yet).
      msg = new Message.empty(key);
      _lookup[key] = msg;
    }

    return msg;
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
   * Add a listener which should be notified when the language changes.
   */
  void addLanguageChangedListener(LanguageChangedListener listener) {
    if (_languageChangedListener == null) {
      _languageChangedListener = new List<LanguageChangedListener>();
    }

    _languageChangedListener.add(listener);
  }

  /**
   * Remove a listener which should be notified when the language changes.
   * Returns whether the listener could be removed.
   */
  bool removeLanguageChangedListener(LanguageChangedListener listener) {
    if (_languageChangedListener != null) {
      return _languageChangedListener.remove(listener);
    }

    return false;
  }

  /**
   * Notify all language changed listeners that the language has changed.
   */
  void _notifyLanguageChanged(String newLocale) {
    if (_languageChangedListener != null) {
      for (LanguageChangedListener listener in _languageChangedListener) {
        listener.call(newLocale);
      }
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

/**
 * Message object holding a translation for a key.
 * This is used primarily as string replacement when the translations are
 * not yet loaded. When the translation file is loaded, the message object is receiving a content.
 */
class Message {
  /**
   * Key of a translation.
   */
  String key;

  /**
   * Content of a translation.
   */
  String content;

  /**
   * Create new message.
   */
  Message(this.key, this.content);

  /**
   * Create empty message.
   */
  Message.empty(this.key) {
    content = "";
  }

  @override
  String toString() {
    return content;
  }
}
