import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/text_util.dart';
import '../badges/format_chip.dart';
import '../badges/score_badge.dart';
import '../badges/status_chip.dart';
import '../image/app_network_image.dart';

enum MediaCardMode { grid, list, compact }

class MediaCard extends StatelessWidget {
  final Map<String, dynamic> media;
  final MediaCardMode mode;
  final VoidCallback? onTap;
  final VoidCallback? onIncrementProgress;
  final int? userProgress;
  final String titlePreference;

  const MediaCard({
    super.key,
    required this.media,
    this.mode = MediaCardMode.grid,
    this.onTap,
    this.onIncrementProgress,
    this.userProgress,
    this.titlePreference = 'ROMAJI',
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case MediaCardMode.list:
        return _buildListCard(context);
      case MediaCardMode.compact:
        return _buildCompactCard(context);
      case MediaCardMode.grid:
        return _buildGridCard(context);
    }
  }

  Widget _buildGridCard(BuildContext context) {
    final title = TextUtil.getPreferredTitle(media['title'], preference: titlePreference);
    final coverUrl = media['coverImage']?['large'] ?? media['coverImage']?['medium'];
    final format = media['format'] as String?;
    final score = (media['averageScore'] as num?)?.toDouble();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  imageUrl: coverUrl,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: AppSpacing.borderRadius8,
                ),
                // Top-left format chip
                if (format != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: FormatChip(format: format),
                  ),
                // Bottom-right score badge
                if (score != null)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: ScoreBadge(score: score),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.p6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final title = TextUtil.getPreferredTitle(media['title'], preference: titlePreference);
    final coverUrl = media['coverImage']?['large'] ?? media['coverImage']?['medium'];
    final format = media['format'] as String?;
    final status = media['status'] as String?;
    final episodes = media['episodes'] as int?;
    final chapters = media['chapters'] as int?;
    final score = (media['averageScore'] as num?)?.toDouble();

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadius12,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.p8),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: AppSpacing.borderRadius12,
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            AppNetworkImage(
              imageUrl: coverUrl,
              width: 65,
              height: 90,
              borderRadius: AppSpacing.borderRadius8,
            ),
            const SizedBox(width: AppSpacing.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (format != null) FormatChip(format: format),
                      if (status != null) StatusChip(status: status),
                      if (score != null) ScoreBadge(score: score),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (userProgress != null)
                        Text(
                          'Progress: $userProgress / ${episodes ?? chapters ?? '?'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (episodes != null)
                        Text(
                          '$episodes eps',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (onIncrementProgress != null)
              IconButton.filledTonal(
                onPressed: onIncrementProgress,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brandBlue.withValues(alpha: 0.15),
                  foregroundColor: AppColors.brandBlue,
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                tooltip: '+1 Episode / Chapter',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    final title = TextUtil.getPreferredTitle(media['title'], preference: titlePreference);
    final coverUrl = media['coverImage']?['medium'];
    final score = (media['averageScore'] as num?)?.toDouble();

    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.p12, vertical: 2),
      leading: AppNetworkImage(
        imageUrl: coverUrl,
        width: 38,
        height: 52,
        borderRadius: AppSpacing.borderRadius4,
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      trailing: score != null ? ScoreBadge(score: score, fontSize: 10) : null,
    );
  }
}
