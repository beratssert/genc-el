extension StringSafeSubstring on String {
  /// Returns a substring from the start to [end], but safely handles 
  /// strings shorter than [end].
  String safeSubstring(int start, [int? end]) {
    if (start >= length) return '';
    int actualEnd = end ?? length;
    if (actualEnd > length) actualEnd = length;
    if (actualEnd < start) return '';
    return substring(start, actualEnd);
  }
}
