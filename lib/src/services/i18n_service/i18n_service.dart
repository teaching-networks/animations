import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:angular/angular.dart';
import "package:intl/intl_browser.dart";

@Injectable()
class I18nService {

  static const String LOCAL_STORAGE_LOCALE = "locale";
  static const List<Language> AVAILABLE_LANGUAGES = const [
    const Language("en", "English"),
    const Language("de", "Deutsch")
  ];
  static const String DEFAULT_LOCALE = "en";
  static const String URL = "/i18n/";
  static const String FILE_ENDING = ".json";

  String _currentLocale;

  Map<String, Message> _lookup = new Map<String, Message>();

  I18nService() {
    // Start locale file lookup.
    getLocale().then((locale) {
      _currentLocale = locale;

      _reload();
    });
  }

  void _reload() {
    _loadLangFile(_currentLocale).then(_initLookup);
  }

  Future<Map<String, String>> _loadLangFile(String locale) async {
    if (!_hasLocale(locale)) {
      locale = DEFAULT_LOCALE;
    }

    return HttpRequest.getString(URL + locale + FILE_ENDING).then((value) {
      try {
        return JSON.decode(value);
      } catch (e) {
        print("Language resource file could not be loaded for locale: $locale");
      }
    });
  }

  void _initLookup(Map<String, String> map) {
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

  String getCurrentLocale() {
    return _currentLocale;
  }

  String getDefaultLocale() {
    return DEFAULT_LOCALE;
  }

  void setLocale(String locale) {
    if (_hasLocale(locale)) {
      window.localStorage[LOCAL_STORAGE_LOCALE] = locale;
      _currentLocale = locale;

      _reload();
    }
  }

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

  List<Language> getLanguages() {
    return AVAILABLE_LANGUAGES;
  }

  void clearLocale() {
    window.localStorage.remove(LOCAL_STORAGE_LOCALE);
  }

  bool _hasLocale(String locale) {
    for (Language lang in AVAILABLE_LANGUAGES) {
      if (lang.locale == locale) {
        return true;
      }
    }

    return false;
  }

}

class Language {

  final String locale;
  final String name;

  const Language(this.locale, this.name);

}

class Message {

  String key;
  String content;

  Message(this.key, this.content);

  Message.empty(this.key) {
    content = "";
  }

  @override
  String toString() {
    return content;
  }

}