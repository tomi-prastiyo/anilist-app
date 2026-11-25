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

  /// Formats AniList MediaFormat enum strings (e.g. TV_SHORT -> TV Short, ONE_SHOT -> One Shot)
  static String formatMediaFormat(String? format) {
    if (format == null || format.isEmpty) return '';
    switch (format.toUpperCase()) {
      case 'TV':
        return 'TV';
      case 'OVA':
        return 'OVA';
      case 'ONA':
        return 'ONA';
      case 'TV_SHORT':
        return 'TV Short';
      case 'MOVIE':
        return 'Movie';
      case 'SPECIAL':
        return 'Special';
      case 'MUSIC':
        return 'Music';
      case 'MANGA':
        return 'Manga';
      case 'NOVEL':
        return 'Light Novel';
      case 'ONE_SHOT':
        return 'One Shot';
      default:
        return toTitleCase(format);
    }
  }

  /// Formats AniList MediaStatus enum strings (e.g. RELEASING -> Airing/Releasing, FINISHED -> Finished)
  static String formatMediaStatus(String? status, {bool isAnime = true}) {
    if (status == null || status.isEmpty) return '';
    switch (status.toUpperCase()) {
      case 'FINISHED':
        return 'Finished';
      case 'RELEASING':
        return isAnime ? 'Airing' : 'Releasing';
      case 'NOT_YET_RELEASED':
        return 'Upcoming';
      case 'CANCELLED':
        return 'Cancelled';
      case 'HIATUS':
        return 'Hiatus';
      default:
        return toTitleCase(status);
    }
  }

  /// Converts SNAKE_CASE or UPPERCASE strings into clean Title Case
  static String toTitleCase(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Cleans raw AniList markdown/HTML into a concise plain-text bio snippet for cards.
  static String? cleanBioSnippet(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var text = raw;
    text = text.replaceAll(RegExp(r'img(?:\d+%?|\d+)?\([^)]+\)', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), '');
    text = text.replaceAll(RegExp(r'webm\([^)]+\)', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'youtube\([^)]+\)', caseSensitive: false), '');
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m.group(1) ?? '');
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    text = text.replaceAllMapped(RegExp(r'^[>#\s~]+', multiLine: true), (_) => '');
    text = text.replaceAll(RegExp(r'[>#~]+'), '');
    text = text.replaceAll(RegExp(r'[*_]{1,3}'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isNotEmpty ? text : null;
  }
}
