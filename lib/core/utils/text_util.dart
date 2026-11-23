class TextUtil {
  TextUtil._();

  /// Strips basic HTML tags from AniList descriptions (e.g. <br>, <i>, <b>)
  static String stripHtml(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) return '';
    return htmlString
        .replaceAll(RegExp(r'\s*<br\s*/?>\s*', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#039;', "'")
        .trim();
  }

  /// Selects title according to user's title language preference
  static String getPreferredTitle(Map<String, dynamic>? titleMap, {String preference = 'ROMAJI'}) {
    if (titleMap == null) return 'Unknown Title';

    final userPreferred = titleMap['userPreferred'] as String?;
    final romaji = titleMap['romaji'] as String?;
    final english = titleMap['english'] as String?;
    final native = titleMap['native'] as String?;

    switch (preference.toUpperCase()) {
      case 'ENGLISH':
        return english ?? romaji ?? userPreferred ?? native ?? 'Unknown';
      case 'NATIVE':
        return native ?? romaji ?? userPreferred ?? english ?? 'Unknown';
      case 'ROMAJI':
      default:
        return romaji ?? english ?? userPreferred ?? native ?? 'Unknown';
    }
  }
}
