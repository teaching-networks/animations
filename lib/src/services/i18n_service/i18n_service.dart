import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import "package:intl/intl_browser.dart";

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
  PlatformLocation _platformLocation;

  /**
   * I18n Service constructor.
   */
  I18nService(this._platformLocation) {
    // Start locale file lookup.
    getLocale().then((locale) {
      _currentLocale = locale;

      _reload();
    });
  }

  /**
   * Reload language file.
   */
  void _reload() {
    _loadLangFile(_currentLocale).then(_initLookup);
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
      window.localStorage[LOCAL_STORAGE_LOCALE] = locale;
      _currentLocale = locale;

      _reload();
    }
  }

  /**
   * Get locale.
   */
  Future<String> getLocale() async {
    String l = window.localStorage[LOCAL_STORAGE_LOCALE];

    if (l == null) {
      return findSystemLocale().then((locale) {
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
    window.localStorage.remove(LOCAL_STORAGE_LOCALE);
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
