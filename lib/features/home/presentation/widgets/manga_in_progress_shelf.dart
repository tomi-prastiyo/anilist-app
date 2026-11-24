import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/text_util.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../media_detail/presentation/media_detail_screen.dart';
import '../../../media_list/presentation/media_list_controller.dart';
import '../../../media_list/presentation/media_list_screen.dart';

class MangaInProgressShelf extends ConsumerWidget {
  const MangaInProgressShelf({super.key});

  static const Color _mangaPurple = Color(0xFF7C57E8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mangaListState = ref.watch(mangaListControllerProvider);

    return mangaListState.maybeWhen(
      data: (lists) {
        // Find current reading list
        final currentList = lists.firstWhere(
          (l) => (l['status'] as String?)?.toUpperCase() == 'CURRENT',
          orElse: () => {'entries': []},
        );

        final rawEntries = (currentList['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (rawEntries.isEmpty) return const SizedBox.shrink();

        // Sort by updatedAt descending
        final allEntries = List<Map<String, dynamic>>.from(rawEntries)
          ..sort((a, b) => (b['updatedAt'] as int? ?? 0).compareTo(a['updatedAt'] as int? ?? 0));

        // Limit to 3 items on the shelf
        final displayEntries = allEntries.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
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
                          color: _mangaPurple,
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
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MediaListScreen(type: 'MANGA'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'View All (${allEntries.length}) →',
                        style: const TextStyle(
                          fontFamily: 'Overpass',
                          color: _mangaPurple,
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

            // Horizontal Carousel of Manga Cards (width 260dp)
            SizedBox(
              height: 116,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
                scrollDirection: Axis.horizontal,
                itemCount: displayEntries.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = displayEntries[index];
                  final media = item['media'] as Map<String, dynamic>;
                  final title = TextUtil.getPreferredTitle(media['title']);
                  final coverUrl = media['coverImage']?['large'] ?? media['coverImage']?['medium'];
                  final progress = item['progress'] as int? ?? 0;
                  final totalChapters = media['chapters'] as int?;
                  final progressPercent = totalChapters != null && totalChapters > 0
                      ? (progress / totalChapters).clamp(0.0, 1.0)
                      : null;

                  void openDetail() {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MediaDetailScreen(mediaId: media['id']),
                      ),
                    );
                  }

                  return Container(
                    width: 260,
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        // Cover Image (Tappable to Detail)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: openDetail,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AppNetworkImage(
                              imageUrl: coverUrl,
                              width: 62,
                              height: 94,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Details Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Title & Reading Status (Tappable to Detail)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: openDetail,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Reading Tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: _mangaPurple.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: _mangaPurple.withValues(alpha: 0.3)),
                                      ),
                                      child: const Text(
                                        'Reading',
                                        style: TextStyle(
                                          fontFamily: 'Overpass',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: _mangaPurple,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Overpass',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: context.appTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Chapter $progress of ${totalChapters ?? '?'}',
                                      style: TextStyle(
                                        fontFamily: 'Overpass',
                                        fontSize: 10.5,
                                        color: context.appTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Progress Bar + Quick Increment (+1)
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: openDetail,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: progressPercent,
                                            backgroundColor: context.appInputSurface,
                                            valueColor: const AlwaysStoppedAnimation<Color>(_mangaPurple),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ref.read(mangaListControllerProvider.notifier).incrementProgress(
                                        entryId: item['id'] as int,
                                        mediaId: media['id'] as int,
                                        currentProgress: progress,
                                        maxEpisodesOrChapters: totalChapters,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF8A68F0),
                                            Color(0xFF6B43DB),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _mangaPurple.withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+1',
                                        style: TextStyle(
                                          fontFamily: 'Overpass',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
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
