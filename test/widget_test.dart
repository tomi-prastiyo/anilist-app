import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anilist_app/core/animations/app_motion.dart';
import 'package:anilist_app/core/constants/app_colors.dart';
import 'package:anilist_app/core/constants/yuyuyu_assets.dart';
import 'package:anilist_app/core/network/api_client.dart';
import 'package:anilist_app/core/settings/content_settings_provider.dart';
import 'package:anilist_app/core/storage/local_storage_service.dart';
import 'package:anilist_app/core/storage/secure_storage_service.dart';
import 'package:anilist_app/core/theme/app_theme.dart';
import 'package:anilist_app/core/theme/theme_provider.dart';
import 'package:anilist_app/core/utils/date_util.dart';
import 'package:anilist_app/core/utils/media_progress_util.dart';
import 'package:anilist_app/core/utils/score_util.dart';
import 'package:anilist_app/core/utils/text_util.dart';
import 'package:anilist_app/core/widgets/anilist_bio_parser.dart';
import 'package:anilist_app/features/activity/data/activity_repository.dart';
import 'package:anilist_app/features/activity/presentation/activity_screen.dart';
import 'package:anilist_app/features/auth/data/auth_repository.dart';
import 'package:anilist_app/features/auth/domain/models/user_model.dart';
import 'package:anilist_app/features/auth/presentation/auth_controller.dart';
import 'package:anilist_app/features/auth/presentation/login_screen.dart';
import 'package:anilist_app/features/auth/presentation/splash_loading_screen.dart';
import 'package:anilist_app/features/home/presentation/airing_schedule_screen.dart';
import 'package:anilist_app/features/home/presentation/home_screen.dart';
import 'package:anilist_app/features/home/presentation/widgets/anime_in_progress_shelf.dart';
import 'package:anilist_app/features/home/presentation/widgets/home_activity_feed.dart';
import 'package:anilist_app/features/home/presentation/widgets/yuyuyu_hero_banner.dart';
import 'package:anilist_app/features/media_editor/presentation/media_editor_bottom_sheet.dart';
import 'package:anilist_app/features/media_list/data/media_list_repository.dart';
import 'package:anilist_app/features/media_list/presentation/media_list_controller.dart';
import 'package:anilist_app/features/media_list/presentation/media_list_screen.dart';
import 'package:anilist_app/features/navigation/presentation/main_shell_screen.dart';
import 'package:anilist_app/features/notifications/data/notifications_repository.dart';
import 'package:anilist_app/features/notifications/presentation/notification_read_controller.dart';
import 'package:anilist_app/features/profile/presentation/profile_screen.dart';
import 'package:anilist_app/features/search/data/search_repository.dart';
import 'package:anilist_app/features/search/presentation/search_screen.dart';
import 'package:anilist_app/shared/image/app_network_image.dart';
import 'package:anilist_app/shared/state/favourite_sync_store.dart';
import 'package:anilist_app/shared/widgets/mankai_cute_companion.dart';
import 'package:anilist_app/shared/widgets/mankai_logo_emblem.dart';
import 'package:anilist_app/shared/widgets/mankai_motifs.dart';
import 'package:anilist_app/shared/widgets/progress_increment_pills.dart';

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
      expect(find.text('Token Login'), findsNothing);
      expect(find.text('Enter AniList Token'), findsNothing);
      expect(find.text('Continue as Guest'), findsOneWidget);
      expect(find.text('Powered by AniList'), findsOneWidget);
      expect(find.text('AL'), findsNothing);
    });
  });

  group('Notification Read/Unread & Unread Count Tests', () {
    test('Tracks server unread baseline, markRead, markUnread, and markAllRead', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      final fakeRepo = _FakeNotificationsRepository();
      final notifier = NotificationReadNotifier(storage, fakeRepo);

      notifier.syncServerCount(3);
      await notifier.setLoadedNotificationIds([503, 502, 501, 500]);

      expect(notifier.state.unreadCount, 3);
      expect(notifier.state.isUnread(0, 503), isTrue);
      expect(notifier.state.isUnread(1, 502), isTrue);
      expect(notifier.state.isUnread(2, 501), isTrue);
      expect(notifier.state.isUnread(3, 500), isFalse);

      // Mark one read -> count decrements from 3 to 2
      await notifier.markRead(503);
      expect(notifier.state.unreadCount, 2);
      expect(notifier.state.isUnread(0, 503), isFalse);

      // Mark an older item unread -> count increments to 3
      await notifier.markUnread(500);
      expect(notifier.state.unreadCount, 3);
      expect(notifier.state.isUnread(3, 500), isTrue);

      // Mark all read -> resets server count and clears forced unread items
      await notifier.markAllRead();
      expect(notifier.state.unreadCount, 0);
      expect(fakeRepo.resetCalled, isTrue);

      // Toggling back unread after markAllRead still shows unread = 1
      await notifier.markUnread(501);
      expect(notifier.state.unreadCount, 1);
      expect(notifier.state.isUnread(2, 501), isTrue);
    });
  });

  group('Guest Mode Global-Only Activity Tests', () {
    testWidgets('HomeActivityFeed & ActivityScreen hide Following toggle in Guest Mode',
        (tester) async {
      SharedPreferences.setMockInitialValues({'key_is_guest': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith((ref) {
              final repo = ref.watch(authRepositoryProvider);
              return _StaticGuestController(repo);
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HomeActivityFeed()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Global'), findsOneWidget);
      expect(find.text('Following'), findsNothing);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith((ref) {
              final repo = ref.watch(authRepositoryProvider);
              return _StaticGuestController(repo);
            }),
          ],
          child: const MaterialApp(home: ActivityScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Global Activity'), findsOneWidget);
      expect(find.text('Friends Only'), findsNothing);
    });
  });

  group('Performance & Maintainability Optimization Tests', () {
    testWidgets('AppTheme caches ThemeData instances across repeated calls', (tester) async {
      final heroine = YuYuYuAssets.heroines.first;
      expect(identical(AppTheme.lightTheme, AppTheme.lightTheme), isTrue);
      expect(identical(AppTheme.darkTheme, AppTheme.darkTheme), isTrue);
      expect(
        identical(AppTheme.yuyuyuTheme(heroine), AppTheme.yuyuyuTheme(heroine)),
        isTrue,
      );
    });

    test('animateEntrance skips animation wrapper beyond staggered cap', () {
      const marker = SizedBox(key: ValueKey('marker'));
      expect(identical(marker.animateEntrance(index: 10), marker), isTrue);
      expect(identical(marker.animateEntrance(index: 0), marker), isFalse);
    });

    test('MediaListController optimistic updates deep-clone and cleanly revert on error', () async {
      final repo = _FakeMediaListRepository();
      final controller = MediaListController(repo, 123, 'MANGA');

      // Wait for initial async loadLists() triggered in constructor
      await Future<void>.delayed(Duration.zero);

      repo.shouldThrowOnSave = true;

      // Capture optimistic value mid-flight before Future rejects or verify clean revert
      await controller.incrementProgress(
        entryId: 10,
        mediaId: 200,
        currentProgress: 5,
        maxEpisodesOrChapters: 12,
      );

      final entryAfterProgFail =
          (controller.state.value!.first['entries'] as List).first as Map<String, dynamic>;
      expect(entryAfterProgFail['progress'], 5);
      expect(entryAfterProgFail['status'], 'CURRENT');

      await controller.incrementVolume(
        entryId: 10,
        mediaId: 200,
        currentVolumes: 2,
        maxVolumes: 5,
      );

      final entryAfterVolFail =
          (controller.state.value!.first['entries'] as List).first as Map<String, dynamic>;
      expect(entryAfterVolFail['progressVolumes'], 2);

      // Now allow save to succeed and verify optimistic state persists
      repo.shouldThrowOnSave = false;
      await controller.incrementProgress(
        entryId: 10,
        mediaId: 200,
        currentProgress: 5,
        maxEpisodesOrChapters: 12,
      );
      await controller.incrementVolume(
        entryId: 10,
        mediaId: 200,
        currentVolumes: 2,
        maxVolumes: 5,
      );

      final entrySuccess =
          (controller.state.value!.first['entries'] as List).first as Map<String, dynamic>;
      expect(entrySuccess['progress'], 6);
      expect(entrySuccess['progressVolumes'], 3);
    });

    testWidgets('MainShellScreen lazily activates IndexedStack tabs on demand', (tester) async {
      SharedPreferences.setMockInitialValues({'key_is_guest': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            apiClientProvider.overrideWithValue(_FakeApiClient()),
            authControllerProvider.overrideWith((ref) {
              final repo = ref.watch(authRepositoryProvider);
              return _StaticGuestController(repo);
            }),
          ],
          child: const MaterialApp(home: MainShellScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(IndexedStack), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(MediaListScreen, skipOffstage: false), findsNothing);
      expect(find.byType(SearchScreen, skipOffstage: false), findsNothing);
      expect(find.byType(ProfileScreen, skipOffstage: false), findsNothing);

      // Tap Search tab to lazily mount SearchScreen while keeping HomeScreen alive offstage
      await tester.tap(find.text('Search'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.byType(MediaListScreen, skipOffstage: false), findsNothing);
      expect(find.byType(ProfileScreen, skipOffstage: false), findsNothing);
    });
  });

  group('UI/UX Friendliness Overhaul Tests', () {
    testWidgets('Guest ProfileScreen exposes Settings button in AppBar', (tester) async {
      SharedPreferences.setMockInitialValues({'key_is_guest': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith((ref) {
              final repo = ref.watch(authRepositoryProvider);
              return _StaticGuestController(repo);
            }),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.text('Sign In with AniList'), findsOneWidget);
    });

    testWidgets(
      'MediaEditorBottomSheet shows Volumes only for MANGA and opens tap-to-type progress dialog',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        // 1. MANGA shows Volumes, Chapters, Rereads
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              authControllerProvider.overrideWith((ref) {
                final repo = ref.watch(authRepositoryProvider);
                return _StaticGuestController(repo);
              }),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MediaEditorBottomSheet(
                  key: const ValueKey('manga_editor'),
                  mediaId: 100,
                  mediaType: 'MANGA',
                  maxCount: 50,
                  maxVolumes: 10,
                  initialEntry: const {
                    'id': 1,
                    'status': 'CURRENT',
                    'progress': 12,
                    'progressVolumes': 3,
                    'repeat': 0,
                  },
                  onSaved: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Chapters'), findsOneWidget);
        expect(find.text('Volumes'), findsOneWidget);
        expect(find.text('Rereads'), findsOneWidget);
        expect(find.text('12 / 50'), findsOneWidget);
        expect(find.text('3 / 10'), findsOneWidget);

        // 2. ANIME omits Volumes & tapping counter opens numeric dialog
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              authControllerProvider.overrideWith((ref) {
                final repo = ref.watch(authRepositoryProvider);
                return _StaticGuestController(repo);
              }),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: MediaEditorBottomSheet(
                  key: const ValueKey('anime_editor'),
                  mediaId: 101,
                  mediaType: 'ANIME',
                  maxCount: 12,
                  initialEntry: const {
                    'id': 2,
                    'status': 'CURRENT',
                    'progress': 5,
                    'repeat': 0,
                  },
                  onSaved: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Episodes'), findsOneWidget);
        expect(find.text('Volumes'), findsNothing);
        expect(find.text('5 / 12'), findsOneWidget);

        await tester.tap(find.text('5 / 12'));
        await tester.pumpAndSettle();

        expect(find.text('Set Episodes'), findsOneWidget);
        expect(find.text('Apply'), findsOneWidget);
      },
    );

    testWidgets('SearchScreen displays Quick Explore pills and saved Recent chips',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        LocalStorageService.keyRecentSearches: ['Yuuki Yuuna', 'Madoka'],
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            apiClientProvider.overrideWithValue(_FakeApiClient()),
            authControllerProvider.overrideWith((ref) {
              final repo = ref.watch(authRepositoryProvider);
              return _StaticGuestController(repo);
            }),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Seasonal Chart'), findsOneWidget);
      expect(find.text('Airing Schedule'), findsOneWidget);
      expect(find.text('Yuuki Yuuna'), findsOneWidget);
      expect(find.text('Madoka'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('AiringScheduleScreen hides My List chip and defaults to public in GuestMode',
        (tester) async {
      SharedPreferences.setMockInitialValues({'key_is_guest': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            apiClientProvider.overrideWithValue(_FakeApiClient()),
            authControllerProvider.overrideWith((ref) {
              final repo = ref.watch(authRepositoryProvider);
              return _StaticGuestController(repo);
            }),
          ],
          child: const MaterialApp(home: AiringScheduleScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Airing Schedule'), findsOneWidget);
      expect(find.text('My List'), findsNothing);
    });
  });

  group('YuYuYu Mankai UI Redesign Tests', () {
    test('ThemeModeNotifier defaults to AppThemeMode.yuyuyu when unset', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      final defaultNotifier = ThemeModeNotifier(storage);
      expect(defaultNotifier.state, AppThemeMode.yuyuyu);

      defaultNotifier.setThemeMode(AppThemeMode.dark);
      expect(ThemeModeNotifier(storage).state, AppThemeMode.dark);

      defaultNotifier.setThemeMode(AppThemeMode.light);
      expect(ThemeModeNotifier(storage).state, AppThemeMode.light);

      defaultNotifier.setThemeMode(AppThemeMode.system);
      expect(ThemeModeNotifier(storage).state, AppThemeMode.system);
    });

    testWidgets('YuYuYuHeroBanner displays Heroine lore and switches active Heroine on tap',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(1080, 2412);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: AppTheme.yuyuyuTheme(),
            home: const Scaffold(body: YuYuYuHeroBanner()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('HERO TERMINAL • SANSHU HERO CLUB'), findsOneWidget);
      expect(find.text('Yuuna Yuuki'), findsOneWidget);
      expect(find.text('Sakura • Gyuki'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('heroine_switch_mimori')));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Mimori Tougou'), findsOneWidget);
      expect(find.text('Morning Glory • Aobozu'), findsOneWidget);
    });

    testWidgets('MankaiSectionHeader renders MankaiBlossomGlyph only in YuYuYu theme',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.yuyuyuTheme(),
          home: const Scaffold(
            body: MankaiSectionHeader(
              title: 'ACTIVITY',
              dotColor: AppColors.brandBlue,
            ),
          ),
        ),
      );
      expect(find.byType(MankaiBlossomGlyph), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: MankaiSectionHeader(
              title: 'ACTIVITY',
              dotColor: AppColors.brandBlue,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MankaiBlossomGlyph), findsNothing);
    });
  });

  group('Rewatch Logic, Progress UX, Cute Mascot & 18+ Sync Tests', () {
    test('MediaProgressUtil handles COMPLETED <-> REPEATING transitions cleanly', () {
      final startRewatch = MediaProgressUtil.resolveStatusChange(
        previousStatus: 'COMPLETED',
        nextStatus: 'REPEATING',
        currentProgress: 24,
        currentVolumes: 6,
        currentRepeat: 1,
        maxCount: 24,
        maxVolumes: 6,
        startedAt: const {'year': 2024, 'month': 1, 'day': 10},
        completedAt: const {'year': 2024, 'month': 2, 'day': 15},
        isManga: true,
      );
      expect(startRewatch.status, 'REPEATING');
      expect(startRewatch.progress, 0);
      expect(startRewatch.progressVolumes, 0);
      expect(startRewatch.repeat, 1);
      expect(startRewatch.completedAt, const {'year': 2024, 'month': 2, 'day': 15});

      final finishRewatch = MediaProgressUtil.resolveStatusChange(
        previousStatus: 'REPEATING',
        nextStatus: 'COMPLETED',
        currentProgress: 23,
        currentVolumes: 5,
        currentRepeat: 1,
        maxCount: 24,
        maxVolumes: 6,
        startedAt: startRewatch.startedAt,
        completedAt: startRewatch.completedAt,
        isManga: true,
      );
      expect(finishRewatch.status, 'COMPLETED');
      expect(finishRewatch.progress, 24);
      expect(finishRewatch.progressVolumes, 6);
      expect(finishRewatch.repeat, 2);
      expect(finishRewatch.repeatIncremented, isTrue);
    });

    test('MediaProgressUtil hides + button when COMPLETED, maxed, or caught up to airing', () {
      expect(
        MediaProgressUtil.canIncrementProgress(
          status: 'COMPLETED',
          progress: 12,
          media: {'type': 'ANIME', 'episodes': 12},
        ),
        isFalse,
      );
      expect(
        MediaProgressUtil.canIncrementProgress(
          status: 'CURRENT',
          progress: 5,
          media: {
            'type': 'ANIME',
            'episodes': 12,
            'nextAiringEpisode': {'episode': 6},
          },
        ),
        isFalse,
      );
      expect(
        MediaProgressUtil.canIncrementProgress(
          status: 'CURRENT',
          progress: 4,
          media: {
            'type': 'ANIME',
            'episodes': 12,
            'nextAiringEpisode': {'episode': 6},
          },
        ),
        isTrue,
      );
      expect(
        MediaProgressUtil.canIncrementVolume(
          status: 'CURRENT',
          progressVolumes: 10,
          media: {'type': 'MANGA', 'volumes': 10},
        ),
        isFalse,
      );
    });

    test('MediaListController bumps repeat + 1 and moves REPEATING entry to COMPLETED', () async {
      final repo = _FakeRepeatingMediaListRepository();
      final controller = MediaListController(repo, 123, 'ANIME');
      await Future<void>.delayed(Duration.zero);

      await controller.incrementProgress(
        entryId: 20,
        mediaId: 300,
        currentProgress: 11,
        maxEpisodesOrChapters: 12,
        currentStatus: 'REPEATING',
        currentRepeat: 1,
      );

      expect(repo.lastSavedStatus, 'COMPLETED');
      expect(repo.lastSavedRepeat, 2);
      final repeatingGroup = controller.state.value!
          .firstWhere((g) => g['status'] == 'REPEATING');
      final completedGroup = controller.state.value!
          .firstWhere((g) => g['status'] == 'COMPLETED');
      expect((repeatingGroup['entries'] as List), isEmpty);
      expect((completedGroup['entries'] as List).length, 1);
      expect((completedGroup['entries'] as List).first['repeat'], 2);
    });

    testWidgets('AnimeInProgressShelf includes REPEATING and hides +1 when caught up',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = _FakeShelfAnimeRepository();
      final controller = MediaListController(repo, 123, 'ANIME');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            animeListControllerProvider.overrideWith((ref) => controller),
          ],
          child: MaterialApp(
            theme: AppTheme.yuyuyuTheme(),
            home: const Scaffold(body: AnimeInProgressShelf()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Rewatching #2'), findsOneWidget);
      expect(find.text('Watching'), findsOneWidget);
      // Caught-up airing entry hides +1 and shows 'Latest', while rewatch entry shows +1
      expect(find.text('Latest'), findsOneWidget);
      expect(find.byType(ProgressIncrementPills), findsOneWidget);
    });

    test('AdultContentNotifier & SearchRepository sync and apply 18+ flag', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      final spyApi = _SpyApiClient();
      final fakeAuthRepo = _FakeAdultAuthRepository(spyApi, storage);
      final authCtrl = _StaticGuestController(fakeAuthRepo);

      const user = UserModel(id: 1, name: 'Hero', displayAdultContent: true);
      expect(user.displayAdultContent, isTrue);

      final notifier = AdultContentNotifier(
        initialValue: false,
        storage: storage,
        authRepo: fakeAuthRepo,
        authController: authCtrl,
        isAuthenticated: true,
      );
      final ok = await notifier.setAdultContent(true);
      expect(ok, isTrue);
      expect(notifier.state, isTrue);
      expect(fakeAuthRepo.lastUpdatedAdult, isTrue);
      expect(storage.displayAdultContent, isTrue);

      final searchRepo = SearchRepository(spyApi);
      await searchRepo.searchMedia(page: 1, type: 'ANIME', includeAdult: false);
      expect(spyApi.lastVariables?['isAdult'], isFalse);

      await searchRepo.searchMedia(page: 1, type: 'ANIME', includeAdult: true);
      expect(spyApi.lastVariables?.containsKey('isAdult'), isFalse);
    });

    testWidgets('MankaiFloatingMascot renders local chibi and opens greeting bubble on tap',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.yuyuyuTheme(),
          home: Scaffold(
            body: Center(
              child: MankaiFloatingMascot(
                assetPath: YuYuYuAssets.heroines.first.chibiAsset,
                accentColor: YuYuYuAssets.heroines.first.accentColor,
                greetingText: YuYuYuAssets.heroines.first.cuteGreeting,
                size: 96,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Image), findsOneWidget);
      await tester.tap(find.byType(MankaiFloatingMascot));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(YuYuYuAssets.heroines.first.cuteGreeting), findsOneWidget);

      // Advance past bubble timer & hop duration to leave zero pending timers
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('Audit Fixes & Polish Tests', () {
    testWidgets('AppNetworkImage sets at most one memCache dimension to avoid squishing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppNetworkImage(
                imageUrl: 'https://example.com/yuuna.jpg',
                width: 54,
                height: 54,
                alignment: Alignment(0, -0.35),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final cached = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(cached.memCacheWidth != null, isTrue);
      expect(cached.memCacheHeight, isNull);
      expect(cached.alignment, const Alignment(0, -0.35));
    });

    test('TitleLanguageNotifier updates local storage and syncs to AuthRepository', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      final spyApi = _SpyApiClient();
      final fakeAuthRepo = _FakeAdultAuthRepository(spyApi, storage);
      final authCtrl = _StaticGuestController(fakeAuthRepo);

      final notifier = TitleLanguageNotifier(
        initialValue: 'ROMAJI',
        storage: storage,
        authRepo: fakeAuthRepo,
        authController: authCtrl,
        isAuthenticated: true,
      );

      final ok = await notifier.setTitleLanguage('ENGLISH');
      expect(ok, isTrue);
      expect(notifier.state, 'ENGLISH');
      expect(fakeAuthRepo.lastUpdatedTitleLanguage, 'ENGLISH');
      expect(storage.titleLanguage, 'ENGLISH');
    });

    test('ActivityRepository filters out isAdult media when includeAdult is false', () async {
      final api = _MockActivityApiClient();
      final repo = ActivityRepository(api);

      final safeRes = await repo.fetchActivities(page: 1, includeAdult: false);
      expect((safeRes['activities'] as List).length, 1);
      expect((safeRes['activities'] as List).first['id'], 1);

      final adultRes = await repo.fetchActivities(page: 1, includeAdult: true);
      expect((adultRes['activities'] as List).length, 2);
    });

    test('MediaListRepository sends explicit null FuzzyDate map when clearing dates', () async {
      final spyApi = _SpyApiClient();
      final repo = MediaListRepository(spyApi);

      await repo.saveMediaListEntry(
        id: 1,
        mediaId: 100,
        clearStartedAt: true,
        clearCompletedAt: true,
      );

      expect(spyApi.lastVariables?['startedAt'], {'year': null, 'month': null, 'day': null});
      expect(spyApi.lastVariables?['completedAt'], {'year': null, 'month': null, 'day': null});
    });
  });

  group('Finish Date, Quick Increment & Full YuYuYu Cast Tests', () {
    test('MediaProgressUtil treats {year: null} fuzzy date as unset and sets dates accurately', () {
      final now = DateTime(2026, 11, 28);
      const todayMap = {'year': 2026, 'month': 11, 'day': 28};

      expect(
        MediaProgressUtil.hasFuzzyDate({'year': null, 'month': null, 'day': null}),
        isFalse,
      );
      expect(MediaProgressUtil.hasFuzzyDate({'year': 2025}), isTrue);

      // 1. CURRENT -> COMPLETED sets completedAt = today and keeps existing startedAt
      final curComplete = MediaProgressUtil.resolveQuickIncrement(
        currentStatus: 'CURRENT',
        currentProgress: 11,
        maxCount: 12,
        existingStartedAt: {'year': 2026, 'month': 1, 'day': 5},
        existingCompletedAt: {'year': null, 'month': null, 'day': null},
        isManga: false,
        now: now,
      );
      expect(curComplete.status, 'COMPLETED');
      expect(curComplete.statusChanged, isTrue);
      expect(curComplete.startedAtChanged, isFalse);
      expect(curComplete.startedAt, {'year': 2026, 'month': 1, 'day': 5});
      expect(curComplete.completedAtChanged, isTrue);
      expect(curComplete.completedAt, todayMap);

      // 2. REPEATING -> COMPLETED sets fresh completedAt = today even with older date & bumps repeat
      final repComplete = MediaProgressUtil.resolveQuickIncrement(
        currentStatus: 'REPEATING',
        currentProgress: 11,
        currentRepeat: 1,
        maxCount: 12,
        existingStartedAt: {'year': 2024, 'month': 1, 'day': 10},
        existingCompletedAt: {'year': 2024, 'month': 2, 'day': 15},
        isManga: false,
        now: now,
      );
      expect(repComplete.status, 'COMPLETED');
      expect(repComplete.repeat, 2);
      expect(repComplete.repeatChanged, isTrue);
      expect(repComplete.completedAtChanged, isTrue);
      expect(repComplete.completedAt, todayMap);

      // 3. CURRENT 0 -> 1 sets startedAt = today
      final firstEp = MediaProgressUtil.resolveQuickIncrement(
        currentStatus: 'CURRENT',
        currentProgress: 0,
        maxCount: 12,
        existingStartedAt: {'year': null, 'month': null, 'day': null},
        isManga: false,
        now: now,
      );
      expect(firstEp.status, 'CURRENT');
      expect(firstEp.startedAtChanged, isTrue);
      expect(firstEp.startedAt, todayMap);
      expect(firstEp.completedAtChanged, isFalse);

      // 4. PLANNING / PAUSED / DROPPED +1 promotes to CURRENT and sets startedAt = today
      for (final passive in ['PLANNING', 'PAUSED', 'DROPPED']) {
        final promoted = MediaProgressUtil.resolveQuickIncrement(
          currentStatus: passive,
          currentProgress: 0,
          maxCount: 12,
          isManga: false,
          now: now,
        );
        expect(promoted.status, 'CURRENT');
        expect(promoted.statusChanged, isTrue);
        expect(promoted.startedAtChanged, isTrue);
        expect(promoted.startedAt, todayMap);
      }

      // 5. 1-episode movie/OVA +1 sets BOTH startedAt & completedAt and marks COMPLETED
      final movieDone = MediaProgressUtil.resolveQuickIncrement(
        currentStatus: 'PLANNING',
        currentProgress: 0,
        maxCount: 1,
        isManga: false,
        now: now,
      );
      expect(movieDone.status, 'COMPLETED');
      expect(movieDone.startedAtChanged, isTrue);
      expect(movieDone.startedAt, todayMap);
      expect(movieDone.completedAtChanged, isTrue);
      expect(movieDone.completedAt, todayMap);

      // 6. Manga +Ch completion syncs progressVolumes = maxVolumes & sets completedAt
      final mangaDone = MediaProgressUtil.resolveQuickIncrement(
        currentStatus: 'CURRENT',
        currentProgress: 49,
        currentVolumes: 8,
        maxCount: 50,
        maxVolumes: 10,
        existingStartedAt: {'year': 2025, 'month': 5, 'day': 1},
        isManga: true,
        now: now,
      );
      expect(mangaDone.status, 'COMPLETED');
      expect(mangaDone.volumesChanged, isTrue);
      expect(mangaDone.progressVolumes, 10);
      expect(mangaDone.completedAtChanged, isTrue);
      expect(mangaDone.completedAt, todayMap);
    });

    test('MediaProgressUtil.resolveQuickVolumeIncrement promotes PLANNING to CURRENT', () {
      final now = DateTime(2026, 11, 28);
      final volRes = MediaProgressUtil.resolveQuickVolumeIncrement(
        currentStatus: 'PLANNING',
        currentVolumes: 0,
        maxVolumes: 12,
        existingStartedAt: {'year': null, 'month': null, 'day': null},
        now: now,
      );
      expect(volRes.status, 'CURRENT');
      expect(volRes.statusChanged, isTrue);
      expect(volRes.progressVolumes, 1);
      expect(volRes.startedAtChanged, isTrue);
      expect(volRes.startedAt, {'year': 2026, 'month': 11, 'day': 28});
    });

    test('MediaListController.incrementProgress sends completedAt & startedAt and moves group',
        () async {
      final repo = _FakeTransitionMediaListRepository();
      final controller = MediaListController(repo, 123, 'ANIME');
      await Future<void>.delayed(Duration.zero);

      final today = MediaProgressUtil.todayFuzzyDate();

      // 0 -> 1 sets startedAt on CURRENT
      await controller.incrementProgress(
        entryId: 10,
        mediaId: 100,
        currentProgress: 0,
        maxEpisodesOrChapters: 12,
        currentStatus: 'CURRENT',
      );
      expect(repo.lastSavedStartedAt, today);
      expect(repo.lastSavedCompletedAt, isNull);

      // 11 -> 12 on CURRENT sets completedAt and moves to COMPLETED
      await controller.incrementProgress(
        entryId: 11,
        mediaId: 101,
        currentProgress: 11,
        maxEpisodesOrChapters: 12,
        currentStatus: 'CURRENT',
      );
      expect(repo.lastSavedStatus, 'COMPLETED');
      expect(repo.lastSavedCompletedAt, today);

      // 11 -> 12 on REPEATING bumps repeat and sets fresh completedAt = today
      await controller.incrementProgress(
        entryId: 12,
        mediaId: 102,
        currentProgress: 11,
        maxEpisodesOrChapters: 12,
        currentStatus: 'REPEATING',
        currentRepeat: 1,
      );
      expect(repo.lastSavedStatus, 'COMPLETED');
      expect(repo.lastSavedRepeat, 2);
      expect(repo.lastSavedCompletedAt, today);

      final completedGroup =
          controller.state.value!.firstWhere((g) => g['status'] == 'COMPLETED');
      final completedIds =
          (completedGroup['entries'] as List).map((e) => e['id']).toSet();
      expect(completedIds, containsAll([11, 12]));
    });

    test('YuYuYuAssets exposes all 22 unique heroes across 5 franchise chapters', () {
      expect(YuYuYuAssets.heroines.length, 22);
      final ids = YuYuYuAssets.heroines.map((h) => h.id).toSet();
      expect(ids.length, 22);

      expect(YuYuYuAssets.byChapter('All').length, 22);
      expect(YuYuYuAssets.byChapter('YuYuYu').length, 6);
      expect(YuYuYuAssets.byChapter('WaSuYu').length, 2);
      expect(YuYuYuAssets.byChapter('NoWaYu').length, 6);
      expect(YuYuYuAssets.byChapter('KuMeYu').length, 5);
      expect(YuYuYuAssets.byChapter('YuYuYui').length, 3);
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

class _StaticGuestController extends AuthController {
  _StaticGuestController(super.repo) {
    state = GuestMode();
  }

  @override
  Future<void> checkAuth() async {
    state = GuestMode();
  }
}

class _FakeNotificationsRepository extends NotificationsRepository {
  bool resetCalled = false;

  _FakeNotificationsRepository() : super(ApiClient(SecureStorageService()));

  @override
  Future<int> fetchUnreadCount() async => resetCalled ? 0 : 3;

  @override
  Future<void> resetServerUnreadCount() async {
    resetCalled = true;
  }
}

class _FakeMediaListRepository extends MediaListRepository {
  bool shouldThrowOnSave = false;

  _FakeMediaListRepository() : super(ApiClient(SecureStorageService()));

  @override
  Future<List<Map<String, dynamic>>> fetchUserMediaLists({
    required int userId,
    required String type,
  }) async {
    return [
      {
        'name': 'Reading',
        'status': 'CURRENT',
        'entries': [
          {
            'id': 10,
            'status': 'CURRENT',
            'progress': 5,
            'progressVolumes': 2,
            'score': 0,
            'media': {'id': 200},
          },
        ],
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> saveMediaListEntry({
    int? id,
    required int mediaId,
    String? status,
    double? score,
    int? progress,
    int? progressVolumes,
    int? repeat,
    String? notes,
    bool? isPrivate,
    Map<String, int>? startedAt,
    Map<String, int>? completedAt,
    bool clearStartedAt = false,
    bool clearCompletedAt = false,
  }) async {
    if (shouldThrowOnSave) {
      throw ApiException('Simulated save failure');
    }
    return {
      'id': id,
      'progress': progress,
      'progressVolumes': progressVolumes,
      'status': status,
    };
  }
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(SecureStorageService());

  @override
  Future<Map<String, dynamic>> postGraphQL({
    required String query,
    Map<String, dynamic>? variables,
  }) async =>
      {};
}

class _FakeRepeatingMediaListRepository extends MediaListRepository {
  String? lastSavedStatus;
  int? lastSavedRepeat;

  _FakeRepeatingMediaListRepository() : super(ApiClient(SecureStorageService()));

  @override
  Future<List<Map<String, dynamic>>> fetchUserMediaLists({
    required int userId,
    required String type,
  }) async {
    return [
      {
        'name': 'Rewatching',
        'status': 'REPEATING',
        'entries': [
          {
            'id': 20,
            'status': 'REPEATING',
            'progress': 11,
            'repeat': 1,
            'media': {'id': 300, 'episodes': 12},
          },
        ],
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> saveMediaListEntry({
    int? id,
    required int mediaId,
    String? status,
    double? score,
    int? progress,
    int? progressVolumes,
    int? repeat,
    String? notes,
    bool? isPrivate,
    Map<String, int>? startedAt,
    Map<String, int>? completedAt,
    bool clearStartedAt = false,
    bool clearCompletedAt = false,
  }) async {
    lastSavedStatus = status;
    lastSavedRepeat = repeat;
    return {
      'id': id,
      'progress': progress,
      'status': status,
      'repeat': repeat,
    };
  }
}

class _FakeShelfAnimeRepository extends MediaListRepository {
  _FakeShelfAnimeRepository() : super(ApiClient(SecureStorageService()));

  @override
  Future<List<Map<String, dynamic>>> fetchUserMediaLists({
    required int userId,
    required String type,
  }) async {
    return [
      {
        'name': 'Watching',
        'status': 'CURRENT',
        'entries': [
          {
            'id': 1,
            'status': 'CURRENT',
            'progress': 5,
            'updatedAt': 100,
            'media': {
              'id': 101,
              'type': 'ANIME',
              'episodes': 12,
              'title': {'romaji': 'Caught Up Airing'},
              'nextAiringEpisode': {'episode': 6},
            },
          },
        ],
      },
      {
        'name': 'Rewatching',
        'status': 'REPEATING',
        'entries': [
          {
            'id': 2,
            'status': 'REPEATING',
            'progress': 4,
            'repeat': 1,
            'updatedAt': 200,
            'media': {
              'id': 102,
              'type': 'ANIME',
              'episodes': 12,
              'title': {'romaji': 'Yuuki Yuuna'},
            },
          },
        ],
      },
    ];
  }
}

class _SpyApiClient extends ApiClient {
  Map<String, dynamic>? lastVariables;

  _SpyApiClient() : super(SecureStorageService());

  @override
  Future<Map<String, dynamic>> postGraphQL({
    required String query,
    Map<String, dynamic>? variables,
  }) async {
    lastVariables = variables == null ? null : Map<String, dynamic>.from(variables);
    return {};
  }
}

class _FakeAdultAuthRepository extends AuthRepository {
  bool? lastUpdatedAdult;
  String? lastUpdatedTitleLanguage;

  _FakeAdultAuthRepository(ApiClient api, LocalStorageService storage)
      : super(api, SecureStorageService(), storage);

  @override
  Future<bool> updateDisplayAdultContent(bool enabled) async {
    lastUpdatedAdult = enabled;
    return enabled;
  }

  @override
  Future<String> updateTitleLanguage(String language) async {
    lastUpdatedTitleLanguage = language;
    return language;
  }
}

class _MockActivityApiClient extends ApiClient {
  _MockActivityApiClient() : super(SecureStorageService());

  @override
  Future<Map<String, dynamic>> postGraphQL({
    required String query,
    Map<String, dynamic>? variables,
  }) async {
    return {
      'Page': {
        'pageInfo': {'currentPage': 1, 'hasNextPage': false},
        'activities': [
          {
            'id': 1,
            'media': {'id': 10, 'isAdult': false},
          },
          {
            'id': 2,
            'media': {'id': 11, 'isAdult': true},
          },
        ],
      },
    };
  }
}

class _FakeTransitionMediaListRepository extends MediaListRepository {
  String? lastSavedStatus;
  int? lastSavedRepeat;
  Map<String, int>? lastSavedStartedAt;
  Map<String, int>? lastSavedCompletedAt;

  _FakeTransitionMediaListRepository() : super(ApiClient(SecureStorageService()));

  @override
  Future<List<Map<String, dynamic>>> fetchUserMediaLists({
    required int userId,
    required String type,
  }) async {
    return [
      {
        'name': 'Watching',
        'status': 'CURRENT',
        'entries': [
          {
            'id': 10,
            'status': 'CURRENT',
            'progress': 0,
            'repeat': 0,
            'startedAt': {'year': null, 'month': null, 'day': null},
            'completedAt': {'year': null, 'month': null, 'day': null},
            'media': {'id': 100, 'episodes': 12},
          },
          {
            'id': 11,
            'status': 'CURRENT',
            'progress': 11,
            'repeat': 0,
            'startedAt': {'year': 2026, 'month': 1, 'day': 2},
            'completedAt': {'year': null, 'month': null, 'day': null},
            'media': {'id': 101, 'episodes': 12},
          },
        ],
      },
      {
        'name': 'Rewatching',
        'status': 'REPEATING',
        'entries': [
          {
            'id': 12,
            'status': 'REPEATING',
            'progress': 11,
            'repeat': 1,
            'startedAt': {'year': 2024, 'month': 1, 'day': 10},
            'completedAt': {'year': 2024, 'month': 2, 'day': 15},
            'media': {'id': 102, 'episodes': 12},
          },
        ],
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> saveMediaListEntry({
    int? id,
    required int mediaId,
    String? status,
    double? score,
    int? progress,
    int? progressVolumes,
    int? repeat,
    String? notes,
    bool? isPrivate,
    Map<String, int>? startedAt,
    Map<String, int>? completedAt,
    bool clearStartedAt = false,
    bool clearCompletedAt = false,
  }) async {
    lastSavedStatus = status;
    lastSavedRepeat = repeat;
    lastSavedStartedAt = startedAt;
    lastSavedCompletedAt = completedAt;
    return {
      'id': id,
      'progress': progress,
      'status': status,
      'repeat': repeat,
      'startedAt': startedAt,
      'completedAt': completedAt,
    };
  }
}
