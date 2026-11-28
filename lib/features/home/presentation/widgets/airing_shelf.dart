import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/yuyuyu_assets.dart';
import '../../../../core/settings/content_settings_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_util.dart';
import '../../../../core/utils/text_util.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../../shared/widgets/mankai_motifs.dart';
import '../../../../shared/widgets/tactile_scale.dart';
import '../../../media_detail/presentation/media_detail_screen.dart';
import '../airing_schedule_screen.dart';

/// Visual-first Airing shelf with poster-dominant tall cards & crisp gradient overlays.
class AiringShelf extends ConsumerWidget {
  final List<Map<String, dynamic>> schedules;

  const AiringShelf({super.key, required this.schedules});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (schedules.isEmpty) return const SizedBox.shrink();
    final titleLang = ref.watch(titleLanguageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MankaiSectionHeader(
          title: 'AIRING TODAY & SOON',
          dotColor: AppColors.statusBehind,
          actionLabel: 'Schedule →',
          onAction: () => Navigator.of(context).push(
            AppPageRoute(page: const AiringScheduleScreen()),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 208,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            scrollDirection: Axis.horizontal,
            itemCount: schedules.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              final media = schedule['media'] as Map<String, dynamic>?;
              final mediaId = media?['id'] as int?;
              final title = TextUtil.getPreferredTitle(media?['title'], preference: titleLang);
              final cover = (media?['coverImage']?['extraLarge'] ??
                  media?['coverImage']?['large'] ??
                  media?['coverImage']?['medium']) as String?;
              final episode = schedule['episode'] as int? ?? 1;
              final timeUntil = schedule['timeUntilAiring'] as int?;
              final airingAt = schedule['airingAt'] as int?;
              final isAired = timeUntil != null && timeUntil <= 0;
              final countdownText = DateUtil.formatCountdown(timeUntil);
              final exactTime = airingAt != null
                  ? DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(airingAt * 1000))
                  : '';
              final subText = isAired
                  ? (exactTime.isNotEmpty ? 'Aired $exactTime' : 'Released Today')
                  : (exactTime.isNotEmpty ? 'Airing $exactTime' : 'Episode $episode Soon');

              return TactileScale(
                onTap: mediaId == null
                    ? null
                    : () => Navigator.of(context).push(
                          AppPageRoute(page: MediaDetailScreen(mediaId: mediaId)),
                        ),
                child: Container(
                  width: 144,
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: context.isYuYuYu
                          ? Color.lerp(context.appBorder, YuYuYuAssets.shinjuGold, 0.30)!
                          : context.appBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: HeroTags.mediaCover(mediaId ?? index, 'airing'),
                        child: AppNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      // Bottom Artwork Scrim
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.48, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.10),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.90),
                            ],
                          ),
                        ),
                      ),
                      // Top-Right Badge
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            gradient: isAired
                                ? const LinearGradient(
                                    colors: [Color(0xFF2E9E60), Color(0xFF227848)],
                                  )
                                : const LinearGradient(
                                    colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                                  ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            'Ep $episode • $countdownText',
                            style: AppTypography.style(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Bottom Title & Airing Time Overlay
                      Positioned(
                        left: 9,
                        right: 9,
                        bottom: 9,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.style(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                height: 1.16,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.style(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animateEntrance(index: index, horizontal: true);
            },
          ),
        ),
      ],
    );
  }
}
