import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/text_util.dart';
import '../../../../shared/widgets/progress_shelf_card.dart';
import '../../../media_detail/presentation/media_detail_screen.dart';
import '../../../media_list/presentation/media_list_controller.dart';
import '../../../media_list/presentation/media_list_screen.dart';

class AnimeInProgressShelf extends ConsumerWidget {
  const AnimeInProgressShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animeListState = ref.watch(animeListControllerProvider);
    final accent = context.isYuYuYu ? context.appAccent : AppColors.brandBlue;

    return animeListState.maybeWhen(
      data: (lists) {
        final currentList = lists.firstWhere(
          (l) => (l['status'] as String?)?.toUpperCase() == 'CURRENT',
          orElse: () => {'entries': []},
        );

        final rawEntries = (currentList['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (rawEntries.isEmpty) return const SizedBox.shrink();

        final allEntries = List<Map<String, dynamic>>.from(rawEntries)
          ..sort((a, b) => (b['updatedAt'] as int? ?? 0).compareTo(a['updatedAt'] as int? ?? 0));
        final displayEntries = allEntries.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.statusWatching,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ANIME IN PROGRESS',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          color: context.appTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      AppPageRoute(page: const MediaListScreen(type: 'ANIME')),
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'View All (${allEntries.length}) →',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          color: accent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 136,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
                scrollDirection: Axis.horizontal,
                itemCount: displayEntries.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = displayEntries[index];
                  final media = item['media'] as Map<String, dynamic>;
                  final mediaId = media['id'] as int;
                  final title = TextUtil.getPreferredTitle(media['title']);
                  final coverUrl = (media['coverImage']?['extraLarge'] ??
                      media['coverImage']?['large'] ??
                      media['coverImage']?['medium']) as String?;
                  final bannerUrl = media['bannerImage'] as String?;
                  final progress = item['progress'] as int? ?? 0;
                  final totalEpisodes = media['episodes'] as int?;

                  final nextAiring = media['nextAiringEpisode'] as Map<String, dynamic>?;
                  final nextEpisodeNum = nextAiring?['episode'] as int?;
                  final latestAired = nextEpisodeNum != null
                      ? nextEpisodeNum - 1
                      : (media['status'] == 'FINISHED' ? totalEpisodes : null);
                  final epsBehind = (latestAired != null && latestAired > progress)
                      ? latestAired - progress
                      : 0;

                  return ProgressShelfCard(
                    mediaId: mediaId,
                    title: title,
                    coverUrl: coverUrl,
                    bannerUrl: bannerUrl,
                    badgeText: epsBehind > 0 ? '$epsBehind eps behind' : 'Watching',
                    badgeColor: epsBehind > 0 ? AppColors.statusBehind : AppColors.statusWatching,
                    subtitleText: 'Episode $progress of ${totalEpisodes ?? '?'}',
                    progress: progress,
                    total: totalEpisodes,
                    accentColor: accent,
                    incrementTextColor: context.isYuYuYu ? Colors.white : AppColors.darkBackground,
                    heroScope: 'home_anime',
                    onTap: () => Navigator.of(context).push(
                      AppPageRoute(page: MediaDetailScreen(mediaId: mediaId)),
                    ),
                    onIncrement: () {
                      ref.read(animeListControllerProvider.notifier).incrementProgress(
                            entryId: item['id'] as int,
                            mediaId: mediaId,
                            currentProgress: progress,
                            maxEpisodesOrChapters: totalEpisodes,
                          );
                    },
                  ).animateEntrance(index: index, horizontal: true);
                },
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
