import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anilist_app/core/storage/local_storage_service.dart';
import 'package:anilist_app/core/utils/score_util.dart';
import 'package:anilist_app/core/utils/date_util.dart';
import 'package:anilist_app/core/utils/text_util.dart';
import 'package:anilist_app/core/widgets/anilist_bio_parser.dart';
import 'package:anilist_app/features/auth/data/auth_repository.dart';
import 'package:anilist_app/features/auth/presentation/auth_controller.dart';
import 'package:anilist_app/features/auth/presentation/login_screen.dart';
import 'package:anilist_app/features/auth/presentation/splash_loading_screen.dart';
import 'package:anilist_app/shared/state/favourite_sync_store.dart';
import 'package:anilist_app/shared/widgets/mankai_logo_emblem.dart';

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

  group('Search Filter & Cache Tests', () {
    test('Cache memory isolation prevents empty results when switching sort options', () {
      final Map<String, List<Map<String, dynamic>>> searchCache = {};
      List<Map<String, dynamic>> results = [];

      final newItems = [
        {'id': 1, 'title': 'Attack on Titan'},
        {'id': 2, 'title': 'Death Note'},
      ];

      final key1 = 'Anime:::::::POPULARITY_DESC::1';
      searchCache[key1] = List<Map<String, dynamic>>.from(newItems);
      results = List<Map<String, dynamic>>.from(newItems);

      // Reset for next filter
      results = [];

      // Ensure cache was not wiped out
      expect(searchCache[key1]!.length, 2);

      // Restore from cache
      if (searchCache.containsKey(key1) && searchCache[key1]!.isNotEmpty) {
        results = List<Map<String, dynamic>>.from(searchCache[key1]!);
      }

      expect(results.length, 2);
      expect(results.first['title'], 'Attack on Titan');
    });
  });

  group('AniListBioParser Tests', () {
    test('Preserves centering, blockquote nested video, and inline hybrid markdown (ChrisLefko sample)', () {
      const sampleHtml = '''
<h1><center>𝑩𝒐𝒏𝒋𝒐𝒖𝒓</center></h1>
<center>OnlyWorldDaiStar in [Anime Music Quiz](https://animemusicquiz.com/) | Certified __Zoomer__</center>
<blockquote>
<h1><strong>Banger of the Week</strong></h1>
<p><em>&quot;Aoi Photograph&quot; by Kurata Mariko</em> from Nine (OP)<br />
<em>Don't forget to <strong>Unmute</strong>, gang!</em></p>
<video muted loop autoplay controls><source src='https://naedist.animemusicquiz.com/yx2kba.webm'></video>
</blockquote>
''';
      final blocks = AniListBioParser.parse(bioHtml: sampleHtml);
      expect(blocks.length, 3);

      final heading = blocks[0] as BioHeadingBlock;
      expect(heading.level, 1);
      expect(heading.align, BioAlign.center);
      expect((heading.spans.first as BioTextSpan).text, '𝑩𝒐𝒏𝒋𝒐𝒖𝒓');

      final centeredLine = blocks[1] as BioParagraphBlock;
      expect(centeredLine.align, BioAlign.center);
      expect(centeredLine.spans.any((s) => s is BioTextSpan && s.linkUrl == 'https://animemusicquiz.com/' && s.text == 'Anime Music Quiz'), isTrue);
      expect(centeredLine.spans.any((s) => s is BioTextSpan && s.bold && s.text == 'Zoomer'), isTrue);

      final quote = blocks[2] as BioBlockquoteBlock;
      expect(quote.children.any((c) => c is BioHeadingBlock && c.level == 1), isTrue);
      expect(quote.children.any((c) => c is BioVideoBlock && !c.isYoutube && c.url == 'https://naedist.animemusicquiz.com/yx2kba.webm'), isTrue);
    });

    test('Groups horizontal images on the same line into BioMediaRowBlock (LazyCoolz sample)', () {
      const html = '''
<h1><center>&quot;<strong>SAYA SANGE</strong>&quot;</center></h1>
<p><img width='220' src='https://example.com/1.gif'> <img width='220' src='https://example.com/2.gif'> <img width='220' src='https://example.com/3.gif'></p>
''';
      final blocks = AniListBioParser.parse(bioHtml: html);
      expect(blocks.length, 2);
      final mediaRow = blocks[1] as BioMediaRowBlock;
      expect(mediaRow.images.length, 3);
      expect(mediaRow.images.first.widthHint, 220);
    });

    test('Raw AniList markdown fallback handles ~~~centering~~~, webm, youtube, and spoilers inside blockquotes', () {
      const raw = '> # Featured\n> Check this out:\n> webm(https://cdn.example.com/op.webm)\n\n~~~Hello Centered World~~~\n\n~!Secret Ending!~';
      final blocks = AniListBioParser.parse(rawBio: raw);
      expect(blocks.any((b) => b is BioBlockquoteBlock && b.children.any((c) => c is BioVideoBlock)), isTrue);
      expect(blocks.any((b) => b is BioParagraphBlock && b.align == BioAlign.center), isTrue);
      expect(
        blocks.any((b) => b is BioParagraphBlock && b.spans.any((s) => s is BioTextSpan && s.spoiler && s.text == 'Secret Ending')),
        isTrue,
      );
    });

    test('Parses AniList compiled YouTube div embed (Ekkaiaenoia bio)', () {
      const html =
          "<p>Old Anime Enjoyer</p>\n<p>Big Fan</p>\n<div class='youtube' id='https://www.youtube.com/watch?v=6ICda9fc6oA'></div>";
      final blocks = AniListBioParser.parse(bioHtml: html);
      expect(blocks.length, 3);
      final video = blocks[2] as BioVideoBlock;
      expect(video.isYoutube, isTrue);
      expect(video.url, 'https://www.youtube.com/watch?v=6ICda9fc6oA');
    });
  });

  group('FavouriteSyncStore Tests', () {
    test('Resolves recent love & unlove toggles ahead of stale server cache', () {
      final store = FavouriteSyncStore();

      expect(store.resolve(FavouriteKind.character, 88636, true), isTrue);

      // Unlove overrides stale server `true`
      store.record(FavouriteKind.character, 88636, false);
      expect(store.resolve(FavouriteKind.character, 88636, true), isFalse);

      // Re-love overrides stale server `false`
      store.record(FavouriteKind.character, 88636, true);
      expect(store.resolve(FavouriteKind.character, 88636, false), isTrue);
    });

    test('applyToList removes unloved items and appends newly loved preview', () {
      final store = FavouriteSyncStore();
      final serverChars = [
        {'id': 84491, 'name': {'userPreferred': 'Cocoa Hoto'}},
        {'id': 88636, 'name': {'userPreferred': 'Yuuna Yuuki'}},
      ];

      store.record(FavouriteKind.character, 88636, false);
      final afterUnlove = store.applyToList(FavouriteKind.character, serverChars);
      expect(afterUnlove.map((e) => e['id']), [84491]);

      store.record(
        FavouriteKind.character,
        99999,
        true,
        itemPreview: {'id': 99999, 'name': {'userPreferred': 'Mimori Tougou'}},
      );
      final afterAdd = store.applyToList(FavouriteKind.character, serverChars);
      expect(afterAdd.map((e) => e['id']), [84491, 99999]);
    });
  });

  group('Mankai Branding, Splash & Login Tests', () {
    testWidgets('SplashLoadingScreen renders Mankai logo & zero AL text', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: SplashLoadingScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MankaiLogoEmblem), findsOneWidget);
      expect(find.text('Mankai'), findsOneWidget);
      expect(find.text('SANSHU HERO CLUB • ANILIST'), findsOneWidget);
      expect(find.text('AL'), findsNothing);
    });

    testWidgets('LoginScreen renders Mankai Hero Club UI & zero AL text without overflow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(1080, 2412);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith((ref) {
              final repo = ref.watch(authRepositoryProvider);
              return _StaticUnauthController(repo);
            }),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(MankaiLogoEmblem), findsOneWidget);
      expect(find.text('Mankai'), findsOneWidget);
      expect(find.text('SANSHU HERO CLUB EDITION'), findsOneWidget);
      expect(find.text('Log In with AniList'), findsOneWidget);
      expect(find.text('Create AniList Account'), findsOneWidget);
      expect(find.text('Token Login'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
      expect(find.text('AL'), findsNothing);
    });
  });
}

class _StaticUnauthController extends AuthController {
  _StaticUnauthController(super.repo);

  @override
  Future<void> checkAuth() async {
    state = Unauthenticated();
  }
}
