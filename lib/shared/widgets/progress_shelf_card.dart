import 'package:flutter/material.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/yuyuyu_assets.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../../shared/widgets/media_progress_bar.dart';
import '../../../../shared/widgets/progress_increment_pills.dart';
import '../../../../shared/widgets/tactile_scale.dart';

/// Shared visual-first progress shelf card with optional banner backdrop & Hero poster.
class ProgressShelfCard extends StatelessWidget {
  final int mediaId;
  final String title;
  final String? coverUrl;
  final String? bannerUrl;
  final String badgeText;
  final Color badgeColor;
  final String subtitleText;
  final int progress;
  final int? total;
  final Color accentColor;
  final Color incrementTextColor;
  final String heroScope;
  final VoidCallback onTap;
  final VoidCallback? onIncrement;
  final VoidCallback? onIncrementVolume;
  final bool isManga;

  const ProgressShelfCard({
    super.key,
    required this.mediaId,
    required this.title,
    required this.coverUrl,
    this.bannerUrl,
    required this.badgeText,
    required this.badgeColor,
    required this.subtitleText,
    required this.progress,
    required this.total,
    required this.accentColor,
    this.incrementTextColor = Colors.white,
    required this.heroScope,
    required this.onTap,
    this.onIncrement,
    this.onIncrementVolume,
    this.isManga = false,
  });

  @override
  Widget build(BuildContext context) {
    final backdrop = bannerUrl ?? coverUrl;
    final isYuYuYu = context.isYuYuYu;
    final cardBorderColor = isYuYuYu
        ? Color.lerp(context.appBorder, YuYuYuAssets.shinjuGold, 0.28)!
        : context.appBorder;

    return TactileScale(
      onTap: onTap,
      child: Container(
        width: onIncrementVolume != null ? 310 : 292,
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
            if (isYuYuYu)
              BoxShadow(
                color: accentColor.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle atmospheric banner artwork in background
            if (backdrop != null)
              Opacity(
                opacity: context.isDark ? 0.16 : 0.09,
                child: AppNetworkImage(
                  imageUrl: backdrop,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    context.appSurface.withValues(alpha: 0.94),
                    context.appSurface.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  // Large crisp Hero Poster
                  Hero(
                    tag: HeroTags.mediaCover(mediaId, heroScope),
                    child: Container(
                      decoration: isYuYuYu
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            )
                          : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: AppNetworkImage(
                          imageUrl: coverUrl,
                          width: 70,
                          height: 102,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.style(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                height: 1.15,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.style(
                                fontSize: 10.5,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: MediaProgressBar(
                                progress: progress,
                                total: total,
                                color: accentColor,
                              ),
                            ),
                            if (onIncrement != null || onIncrementVolume != null) ...[
                              const SizedBox(width: 8),
                              ProgressIncrementPills(
                                accentColor: accentColor,
                                primaryTextColor: incrementTextColor,
                                isManga: isManga,
                                onIncrementPrimary: onIncrement,
                                onIncrementVolume: onIncrementVolume,
                              ),
                            ] else ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: context.appInputSurface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: context.appBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      size: 11,
                                      color: accentColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Latest',
                                      style: TextStyle(
                                        fontFamily: 'Overpass',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: context.appTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
