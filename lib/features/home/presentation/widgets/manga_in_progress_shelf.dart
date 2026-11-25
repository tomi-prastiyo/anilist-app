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

class MangaInProgressShelf extends ConsumerWidget {
  const MangaInProgressShelf({super.key});

  static const Color _mangaPurple = Color(0xFF7C57E8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mangaListState = ref.watch(mangaListControllerProvider);
    final accent = context.isYuYuYu ? context.appSecondaryAccent : _mangaPurple;

    return mangaListState.maybeWhen(
      data: (lists) {
        final currentList = lists.firstWhere(
          (l) => (l['status'] as String?)?.toUpperCase() == 'CURRENT',
          orElse: () => {'entries': []},
        );

        final rawEntries = (currentList['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (rawEntries.isEmpty) return const SizedBox.shrink();

        final allEntries = List<Map<String, dynamic>>.from(rawEntries)
          ..sort((a, b) => (b['updatedAt'] as int? ?? 0).compareTo(a['updatedAt'] as int? ?? 0));
        final displayEntries = allEntries.take(5).toList();

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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MANGA IN PROGRESS',
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
                      AppPageRoute(page: const MediaListScreen(type: 'MANGA')),
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
                  final totalChapters = media['chapters'] as int?;
                  final progressVolumes = item['progressVolumes'] as int? ?? 0;
                  final totalVolumes = media['volumes'] as int?;

                  return ProgressShelfCard(
                    mediaId: mediaId,
                    title: title,
                    coverUrl: coverUrl,
                    bannerUrl: bannerUrl,
                    badgeText: 'Reading',
                    badgeColor: accent,
                    subtitleText: 'Ch $progress/${totalChapters ?? '?'} • Vol $progressVolumes/${totalVolumes ?? '?'}',
                    progress: progress,
                    total: totalChapters,
                    accentColor: accent,
                    incrementTextColor: context.isYuYuYu ? Colors.black : Colors.white,
                    heroScope: 'home_manga',
                    onTap: () => Navigator.of(context).push(
                      AppPageRoute(page: MediaDetailScreen(mediaId: mediaId)),
                    ),
                    onIncrement: () {
                      ref.read(mangaListControllerProvider.notifier).incrementProgress(
                            entryId: item['id'] as int,
                            mediaId: mediaId,
                            currentProgress: progress,
                            maxEpisodesOrChapters: totalChapters,
                          );
                    },
                    onIncrementVolume: () {
                      ref.read(mangaListControllerProvider.notifier).incrementVolume(
                            entryId: item['id'] as int,
                            mediaId: mediaId,
                            currentVolumes: progressVolumes,
                            maxVolumes: totalVolumes,
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
