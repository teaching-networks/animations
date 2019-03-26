/// Utility class for methods dealing with names.
class NameUtil {
  /// Characters allowed in a group URL.
  static const String _urlAllowedChars = "abcdefghijklmnopqrstuvwxyz";

  /// This is used to convert names to URL compliant strings.
  /// Example:
  /// When you pass something like "My animation group name!"
  /// all characters except letters from a-z are replaced by a "-" symbol.
  /// The outcome of the example would be "my-animation-group-name".
  static String makeUrlCompliant(String name) {
    name = name.toLowerCase().trim();

    Runes allowedRunes = _urlAllowedChars.runes;
    int underscoreChar = "-".runes.first;

    StringBuffer urlBuffer = StringBuffer();
    bool writeUnderscore = false;
    for (final rune in name.runes) {
      if (allowedRunes.contains(rune)) {
        if (writeUnderscore) {
          writeUnderscore = false;
          urlBuffer.writeCharCode(underscoreChar);
        }

        urlBuffer.writeCharCode(rune);
      } else {
        writeUnderscore = true;
      }
    }

    return urlBuffer.toString();
  }
}
