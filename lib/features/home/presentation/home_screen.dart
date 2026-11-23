import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/cards/media_card.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/image/app_avatar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import 'home_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeDataProvider);
    final authState = ref.watch(authControllerProvider);

    final user = authState is Authenticated ? authState.user : null;
    final userName = user?.name ?? 'Guest';
    final userAvatar = user?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.p16,
        title: Row(
          children: [
            AppAvatar(imageUrl: userAvatar, size: 36),
            const SizedBox(width: AppSpacing.p12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName 👋',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  user != null ? 'Track your anime & manga' : 'Browsing as Guest',
                  style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          ],
        ),
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
          onRetry: () => ref.read(homeDataProvider.notifier).refresh(),
        ),
        data: (data) {
          final trendingAnime = (data['trendingAnime']?['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final popularSeason = (data['popularSeason']?['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final trendingManga = (data['trendingManga']?['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final topRated = (data['topRated']?['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          return RefreshIndicator(
            onRefresh: () => ref.read(homeDataProvider.notifier).refresh(),
            color: AppColors.brandBlue,
            backgroundColor: AppColors.darkCard,
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.p32),
              children: [
                _buildSection(
                  context,
                  title: '🔥 Trending Anime',
                  items: trendingAnime,
                ),
                _buildSection(
                  context,
                  title: '✨ Popular This Season',
                  items: popularSeason,
                ),
                _buildSection(
                  context,
                  title: '📖 Trending Manga',
                  items: trendingManga,
                ),
                _buildSection(
                  context,
                  title: '⭐ All-Time Top Rated',
                  items: topRated,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.p16, AppSpacing.p20, AppSpacing.p16, AppSpacing.p12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.p12),
            itemBuilder: (context, index) {
              final media = items[index];
              return SizedBox(
                width: 125,
                child: MediaCard(
                  media: media,
                  mode: MediaCardMode.grid,
                  onTap: () {
                    final mediaId = media['id'] as int?;
                    if (mediaId != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MediaDetailScreen(mediaId: mediaId),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
