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

  Future<Map<String, String>> _future;

  Map<String, String> _lookup;

  I18nService() {
    _future = getLocale().then((locale) {
      _currentLocale = locale;

      _loadLangFile(locale).then((map) {
        _lookup = map;
      });
    });
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

  String get(String key) {
    if (_lookup != null) {
      String value = _lookup[key];

      if (value == null) {
        return "[$key not found]";
      } else {
        return value;
      }
    } else {
      return "Loading...";
    }
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