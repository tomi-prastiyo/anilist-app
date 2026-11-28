import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/yuyuyu_assets.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/image/app_avatar.dart';
import '../../../shared/widgets/mankai_logo_emblem.dart';
import '../../../shared/widgets/mankai_motifs.dart';
import '../../../shared/widgets/notification_bell_button.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media_list/presentation/media_list_controller.dart';
import '../../notifications/presentation/notification_read_controller.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../seasonal/presentation/seasonal_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'airing_schedule_screen.dart';
import 'home_controller.dart';
import 'widgets/airing_shelf.dart';
import 'widgets/anime_in_progress_shelf.dart';
import 'widgets/home_activity_feed.dart';
import 'widgets/manga_in_progress_shelf.dart';
import 'widgets/yuyuyu_hero_banner.dart';

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
    final isYuYuYu = context.isYuYuYu;
    final heroine = ref.watch(yuyuyuHeroineProvider);

    final user = authState is Authenticated ? authState.user : null;
    final userName = user?.name ?? 'Guest';
    final userAvatar = user?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.p16,
        title: InkWell(
          onTap: () {
            if (user != null) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                if (user == null && isYuYuYu)
                  MankaiLogoEmblem(size: 36, radius: 11, accentColor: heroine.accentColor)
                else if (isYuYuYu)
                  Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: AppAvatar(imageUrl: userAvatar, size: 34),
                  )
                else
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
                      isYuYuYu
                          ? (user != null
                              ? 'Sanshu Hero Club • ${heroine.roleTitle}'
                              : 'Hero Club Guest • ${heroine.name}')
                          : (user != null ? 'Track your anime & manga' : 'Browsing as Guest'),
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
            const NotificationBellButton()
          else
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
        ],
        bottom: isYuYuYu
            ? const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: MankaiGoldHairline(),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(homeDataProvider.notifier).refresh(),
            ref.read(animeListControllerProvider.notifier).loadLists(),
            ref.read(mangaListControllerProvider.notifier).loadLists(),
            if (user != null)
              ref.read(notificationReadProvider.notifier).refreshFromServer(),
            _activityFeedKey.currentState?.loadActivities() ?? Future.value(),
          ]);
        },
        color: context.appAccent,
        backgroundColor: context.appSurface,
        child: ListView(
          padding: const EdgeInsets.only(top: 6, bottom: 24),
          children: [
            // 0. YuYuYu Hero Club Banner (only shown when YuYuYu theme is active)
            const YuYuYuHeroBanner(),

            // Quick Explore Shortcut Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.p16, 2, AppSpacing.p16, 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickExplorePill(
                      icon: Icons.calendar_month_rounded,
                      label: 'Airing Schedule',
                      accentColor: context.appAccent,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AiringScheduleScreen()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _QuickExplorePill(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Seasonal Chart',
                      accentColor: isYuYuYu ? YuYuYuAssets.shinjuGold : AppColors.brandBlue,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SeasonalScreen()),
                      ),
                    ),
                    if (user == null) ...[
                      const SizedBox(width: 8),
                      _QuickExplorePill(
                        icon: Icons.login_rounded,
                        label: 'Sign In',
                        accentColor: isYuYuYu ? context.appAccent : AppColors.statusCompleted,
                        filled: true,
                        onTap: () => ref.read(authControllerProvider.notifier).logout(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 1. Airing Shelf (Filtered strictly to anime in user's list, never destroys siblings below)
            homeState.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: ShimmerHorizontalRow(height: 208, itemWidth: 144),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (data) {
                final animeLists = ref.watch(animeListControllerProvider).valueOrNull ?? const [];
                final myMediaIds = <int>{};
                for (final group in animeLists) {
                  final entries = (group['entries'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
                  for (final e in entries) {
                    final mid = e['media']?['id'] as int?;
                    if (mid != null) myMediaIds.add(mid);
                  }
                }
                final rawSchedules = (data['airingToday']?['airingSchedules'] as List?)
                        ?.cast<Map<String, dynamic>>() ??
                    [];
                final airingSchedules = rawSchedules.where((s) {
                  final mid = s['media']?['id'] as int?;
                  return mid != null && myMediaIds.contains(mid);
                }).toList();

                if (airingSchedules.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    AiringShelf(schedules: airingSchedules),
                    const SizedBox(height: 18),
                  ],
                );
              },
            ),

            // 2. Anime In Progress (Backdrop Cards + Hero Posters)
            const AnimeInProgressShelf(),
            const SizedBox(height: 18),

            // 3. Manga In Progress (Backdrop Cards + Hero Posters)
            const MangaInProgressShelf(),
            const SizedBox(height: 18),

            // 4. Community Activity Feed (stays mounted — never reloads twice!)
            HomeActivityFeed(key: _activityFeedKey),
          ],
        ),
      ),
    );
  }
}

class _QuickExplorePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;
  final bool filled;

  const _QuickExplorePill({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isYuYuYu = context.isYuYuYu;
    final filledForeground = accentColor.computeLuminance() > 0.55 ? Colors.black : Colors.white;

    return Material(
      color: filled ? accentColor : context.appSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled
                  ? accentColor
                  : (isYuYuYu ? YuYuYuAssets.shinjuGold.withValues(alpha: 0.28) : context.appBorder),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: filled ? filledForeground : accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: filled ? filledForeground : context.appTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
