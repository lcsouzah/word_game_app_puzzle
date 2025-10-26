/// Returns [source] with only the first alphabetical character converted to
/// uppercase and the remainder of the string in lowercase. Whitespace at the
/// beginning/end is preserved, but the returned string is normalized so the
/// casing is predictable for UI labels.
String titleCaseFirstOnly(String source) {
  if (source.isEmpty) {
    return source;
  }

  final buffer = StringBuffer();
  bool converted = false;
  for (var i = 0; i < source.length; i++) {
    final char = source[i];
    if (!converted && _isLetter(char)) {
      buffer.write(char.toUpperCase());
      converted = true;
    } else {
      buffer.write(converted ? char.toLowerCase() : char);
    }
  }
  return buffer.toString();
}

bool _isLetter(String character) {
  if (character.isEmpty) return false;
  final code = character.codeUnitAt(0);
  return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
}