import 'package:flutter_test/flutter_test.dart';
import 'package:anilist_app/core/utils/score_util.dart';
import 'package:anilist_app/core/utils/date_util.dart';
import 'package:anilist_app/core/utils/text_util.dart';

void main() {
  group('ScoreUtil Tests', () {
    test('Formats score correctly across scoring formats', () {
      expect(ScoreUtil.formatScore(85, format: 'POINT_100'), '85%');
      expect(ScoreUtil.formatScore(85, format: 'POINT_10_DECIMAL'), '8.5');
      expect(ScoreUtil.formatScore(85, format: 'POINT_10'), '9/10');
      expect(ScoreUtil.formatScore(85, format: 'POINT_5'), '4/5 ★');
      expect(ScoreUtil.formatScore(85, format: 'POINT_3'), ':)');
    });

    test('Handles null or zero score gracefully', () {
      expect(ScoreUtil.formatScore(null), '-');
      expect(ScoreUtil.formatScore(0), '-');
    });
  });

  group('DateUtil Tests', () {
    test('Fuzzy date formatting', () {
      expect(DateUtil.formatFuzzyDate({'year': 2024, 'month': 4, 'day': 1}), 'Apr 1, 2024');
      expect(DateUtil.formatFuzzyDate({'year': 2024, 'month': 4}), 'Apr 2024');
      expect(DateUtil.formatFuzzyDate({'year': 2024}), '2024');
      expect(DateUtil.formatFuzzyDate(null), '?');
    });

    test('Countdown formatting', () {
      expect(DateUtil.formatCountdown(3600), '1h 0m');
      expect(DateUtil.formatCountdown(86400 + 3600), '1d 1h');
      expect(DateUtil.formatCountdown(0), 'Aired');
    });
  });

  group('TextUtil Tests', () {
    test('Strips html tags correctly', () {
      expect(TextUtil.stripHtml('<b>Hello</b> <br>world!'), 'Hello\nworld!');
      expect(TextUtil.stripHtml('&quot;AniList&quot; &amp; Manga'), '"AniList" & Manga');
    });

    test('Selects user preferred title', () {
      final titleMap = {
        'romaji': 'Sousou no Frieren',
        'english': 'Frieren: Beyond Journey\'s End',
        'native': '葬送のフリーレン',
      };
      expect(TextUtil.getPreferredTitle(titleMap, preference: 'ROMAJI'), 'Sousou no Frieren');
      expect(TextUtil.getPreferredTitle(titleMap, preference: 'ENGLISH'), 'Frieren: Beyond Journey\'s End');
      expect(TextUtil.getPreferredTitle(titleMap, preference: 'NATIVE'), '葬送のフリーレン');
    });
  });
}
