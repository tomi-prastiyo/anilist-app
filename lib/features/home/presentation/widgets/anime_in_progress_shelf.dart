import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/settings/content_settings_provider.dart';
import '../../../../core/utils/media_progress_util.dart';
import '../../../../core/utils/text_util.dart';
import '../../../../shared/widgets/mankai_motifs.dart';
import '../../../../shared/widgets/progress_shelf_card.dart';
import '../../../media_detail/presentation/media_detail_screen.dart';
import '../../../media_list/presentation/media_list_controller.dart';
import '../../../media_list/presentation/media_list_screen.dart';

class AnimeInProgressShelf extends ConsumerWidget {
  const AnimeInProgressShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animeListState = ref.watch(animeListControllerProvider);
    final titleLang = ref.watch(titleLanguageProvider);
    final accent = context.isYuYuYu ? context.appAccent : AppColors.brandBlue;

    return animeListState.maybeWhen(
      data: (lists) {
        final seenIds = <int>{};
        final combinedEntries = <Map<String, dynamic>>[];
        for (final group in lists) {
          final st = (group['status'] as String?)?.toUpperCase();
          if (st != 'CURRENT' && st != 'REPEATING') continue;
          final entries = (group['entries'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          for (final entry in entries) {
            final id = entry['id'] as int?;
            if (id != null && !seenIds.add(id)) continue;
            combinedEntries.add({
              ...entry,
              '_groupStatus': st,
            });
          }
        }
        if (combinedEntries.isEmpty) return const SizedBox.shrink();

        final allEntries = List<Map<String, dynamic>>.from(combinedEntries)
          ..sort((a, b) => (b['updatedAt'] as int? ?? 0).compareTo(a['updatedAt'] as int? ?? 0));
        final displayEntries = allEntries.take(8).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MankaiSectionHeader(
              title: 'ANIME IN PROGRESS',
              dotColor: AppColors.statusWatching,
              actionLabel: 'View All (${allEntries.length}) →',
              actionColor: accent,
              onAction: () => Navigator.of(context).push(
                AppPageRoute(page: const MediaListScreen(type: 'ANIME')),
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
                  final title = TextUtil.getPreferredTitle(media['title'], preference: titleLang);
                  final coverUrl = (media['coverImage']?['extraLarge'] ??
                      media['coverImage']?['large'] ??
                      media['coverImage']?['medium']) as String?;
                  final bannerUrl = media['bannerImage'] as String?;
                  final progress = item['progress'] as int? ?? 0;
                  final totalEpisodes = media['episodes'] as int?;
                  final entryStatus = (item['status'] as String? ?? item['_groupStatus'] as String?)?.toUpperCase() ?? 'CURRENT';
                  final isRewatching = entryStatus == 'REPEATING';
                  final repeatCount = item['repeat'] as int? ?? 0;

                  final latestAired = MediaProgressUtil.latestAiredEpisode(media) ??
                      (media['status'] == 'FINISHED' ? totalEpisodes : null);
                  final epsBehind = (!isRewatching && latestAired != null && latestAired > progress)
                      ? latestAired - progress
                      : 0;
                  final canIncrement = MediaProgressUtil.canIncrementProgress(
                    status: entryStatus,
                    progress: progress,
                    media: media,
                  );
                  final badgeText = isRewatching
                      ? (repeatCount > 0 ? 'Rewatching #${repeatCount + 1}' : 'Rewatching')
                      : (epsBehind > 0 ? '$epsBehind eps behind' : 'Watching');
                  final badgeColor = isRewatching
                      ? AppColors.statusRepeating
                      : (epsBehind > 0 ? AppColors.statusBehind : AppColors.statusWatching);

                  return ProgressShelfCard(
                    mediaId: mediaId,
                    title: title,
                    coverUrl: coverUrl,
                    bannerUrl: bannerUrl,
                    badgeText: badgeText,
                    badgeColor: badgeColor,
                    subtitleText: 'Episode $progress of ${totalEpisodes ?? '?'}',
                    progress: progress,
                    total: totalEpisodes,
                    accentColor: accent,
                    incrementTextColor: accent.computeLuminance() > 0.55 ? Colors.black : Colors.white,
                    heroScope: 'home_anime',
                    onTap: () => Navigator.of(context).push(
                      AppPageRoute(page: MediaDetailScreen(mediaId: mediaId)),
                    ),
                    onIncrement: canIncrement
                        ? () {
                            ref.read(animeListControllerProvider.notifier).incrementProgress(
                                  entryId: item['id'] as int,
                                  mediaId: mediaId,
                                  currentProgress: progress,
                                  maxEpisodesOrChapters: totalEpisodes,
                                  currentStatus: entryStatus,
                                  currentRepeat: repeatCount,
                                );
                          }
                        : null,
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
