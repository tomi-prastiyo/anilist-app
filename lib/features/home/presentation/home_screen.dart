import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/image/app_avatar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media_list/presentation/media_list_controller.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'home_controller.dart';
import 'widgets/airing_shelf.dart';
import 'widgets/anime_in_progress_shelf.dart';
import 'widgets/home_activity_feed.dart';
import 'widgets/manga_in_progress_shelf.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<HomeActivityFeedState> _activityFeedKey = GlobalKey<HomeActivityFeedState>();

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeDataProvider);
    final authState = ref.watch(authControllerProvider);

    final user = authState is Authenticated ? authState.user : null;
    final userName = user?.name ?? 'Guest';
    final userAvatar = user?.avatarUrl;
    final unreadCount = user?.unreadNotificationCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.p16,
        title: InkWell(
          onTap: () {
            if (user != null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                AppAvatar(imageUrl: userAvatar, size: 36),
                const SizedBox(width: AppSpacing.p12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $userName 👋',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                    Text(
                      user != null ? 'Track your anime & manga' : 'Browsing as Guest',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 11.5,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (user != null)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.statusBehind,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: homeState.when(
        loading: () => const SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 16),
              ShimmerMediaGrid(count: 6),
            ],
          ),
        ),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () {
            ref.read(homeDataProvider.notifier).refresh();
            ref.read(animeListControllerProvider.notifier).loadLists();
            ref.read(mangaListControllerProvider.notifier).loadLists();
            _activityFeedKey.currentState?.loadActivities();
          },
        ),
        data: (data) {
          final airingSchedules = (data['airingToday']?['airingSchedules'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.read(homeDataProvider.notifier).refresh(),
                ref.read(animeListControllerProvider.notifier).loadLists(),
                ref.read(mangaListControllerProvider.notifier).loadLists(),
                _activityFeedKey.currentState?.loadActivities() ?? Future.value(),
              ]);
            },
            color: AppColors.brandBlue,
            backgroundColor: context.appSurface,
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 90),
              children: [
                // 1. Airing Shelf (Schedule with countdown timers)
                if (airingSchedules.isNotEmpty) ...[
                  AiringShelf(schedules: airingSchedules),
                  const SizedBox(height: 18),
                ],

                // 2. Anime In Progress (3-4 items + View All)
                const AnimeInProgressShelf(),
                const SizedBox(height: 18),

                // 3. Manga In Progress (2-3 items + View All)
                const MangaInProgressShelf(),
                const SizedBox(height: 18),

                // 4. Community Activity Feed (Following default vs Global, Like button)
                HomeActivityFeed(key: _activityFeedKey),
              ],
            ),
          );
        },
      ),
    );
  }
}
