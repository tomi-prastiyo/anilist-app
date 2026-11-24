import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/score_util.dart';
import '../../core/utils/text_util.dart';
import '../badges/format_chip.dart';
import '../image/app_network_image.dart';

enum MediaCardMode { grid, list, compact }

class MediaCard extends StatelessWidget {
  final Map<String, dynamic> media;
  final MediaCardMode mode;
  final VoidCallback? onTap;
  final VoidCallback? onIncrementProgress;
  final VoidCallback? onUpdateScore;
  final int? userProgress;
  final double? userScore;
  final String scoreFormat;
  final String titlePreference;
  final Color? accentColor;
  final String? listStatus;

  const MediaCard({
    super.key,
    required this.media,
    this.mode = MediaCardMode.list,
    this.onTap,
    this.onIncrementProgress,
    this.onUpdateScore,
    this.userProgress,
    this.userScore,
    this.scoreFormat = 'POINT_100',
    this.titlePreference = 'ROMAJI',
    this.accentColor,
    this.listStatus,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case MediaCardMode.list:
        return _buildNeoCard(context);
      case MediaCardMode.compact:
        return _buildCompactCard(context);
      case MediaCardMode.grid:
        return _buildGridCard(context);
    }
  }

  /// Model 1: Neo-Card Detailed (Matching Home Screen Progress Cards)
  Widget _buildNeoCard(BuildContext context) {
    final title = TextUtil.getPreferredTitle(media['title'], preference: titlePreference);
    final coverUrl = media['coverImage']?['large'] ?? media['coverImage']?['medium'];
    final format = media['format'] as String? ?? 'TV';
    final episodes = media['episodes'] as int?;
    final chapters = media['chapters'] as int?;
    final totalUnits = episodes ?? chapters;
    final progress = userProgress ?? 0;
    final progressPercent = totalUnits != null && totalUnits > 0
        ? (progress / totalUnits).clamp(0.0, 1.0)
        : null;

    final color = accentColor ?? AppColors.brandBlue;

    // Airing and Behind schedule calculations
    final nextAiring = media['nextAiringEpisode'] as Map<String, dynamic>?;
    final nextEpisodeNum = nextAiring?['episode'] as int?;
    final latestAired = nextEpisodeNum != null
        ? nextEpisodeNum - 1
        : (media['status'] == 'FINISHED' ? totalUnits : null);
    final epsBehind = (latestAired != null && latestAired > progress)
        ? latestAired - progress
        : 0;

    final isManga = chapters != null || media['type'] == 'MANGA';
    final unitLabel = isManga ? 'Chapter' : 'Episode';
    final bool isPersonalList = userProgress != null ||
        onIncrementProgress != null ||
        onUpdateScore != null ||
        listStatus != null;
    final avgScore = media['averageScore'] as int?;
    final status = media['status'] as String?;
    final year = media['seasonYear'] ?? media['startDate']?['year'];
    final rawGenres = (media['genres'] as List?)?.cast<String>() ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
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
            // Cover Image with Format Pill
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AppNetworkImage(
                    imageUrl: coverUrl,
                    width: 62,
                    height: 94,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 3,
                  left: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      format,
                      style: const TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // Details Column
            Expanded(
              child: !isPersonalList
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Global Average Score + Status Pill
                            Row(
                              children: [
                                if (avgScore != null && avgScore > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (avgScore >= 75
                                              ? const Color(0xFF46C07B)
                                              : (avgScore >= 60 ? const Color(0xFFE5A158) : const Color(0xFFE85D75)))
                                          .withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: (avgScore >= 75
                                                ? const Color(0xFF46C07B)
                                                : (avgScore >= 60 ? const Color(0xFFE5A158) : const Color(0xFFE85D75)))
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 12,
                                          color: avgScore >= 75
                                              ? const Color(0xFF46C07B)
                                              : (avgScore >= 60 ? const Color(0xFFE5A158) : const Color(0xFFE85D75)),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$avgScore%',
                                          style: TextStyle(
                                            fontFamily: 'Overpass',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: avgScore >= 75
                                                ? const Color(0xFF46C07B)
                                                : (avgScore >= 60 ? const Color(0xFFE5A158) : const Color(0xFFE85D75)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (status != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: status == 'RELEASING'
                                          ? const Color(0xFF46C07B).withValues(alpha: 0.12)
                                          : AppColors.brandBlue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status == 'RELEASING' ? 'AIRING' : status,
                                      style: TextStyle(
                                        fontFamily: 'Overpass',
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: status == 'RELEASING' ? const Color(0xFF46C07B) : AppColors.brandBlue,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            // Title
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Overpass',
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Metadata (Episodes/Chapters • Year)
                            Text(
                              [
                                if (episodes != null) '$episodes eps' else if (chapters != null) '$chapters ch',
                                if (year != null) '$year',
                              ].join(' • '),
                              style: const TextStyle(
                                fontFamily: 'Overpass',
                                fontSize: 10.5,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ],
                        ),

                        // Genres Tag Row
                        if (rawGenres.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: rawGenres.take(3).map((g) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkSurfaceInput,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                  ),
                                  child: Text(
                                    g,
                                    style: const TextStyle(
                                      fontFamily: 'Overpass',
                                      fontSize: 9,
                                      color: AppColors.darkTextSecondary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Pill + Personal Score Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                          // Status / Behind badge
                          if (listStatus == 'REPEATING')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (isManga ? const Color(0xFF7C57E8) : AppColors.brandBlue).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: (isManga ? const Color(0xFF7C57E8) : AppColors.brandBlue).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                isManga ? 'Rereading' : 'Rewatching',
                                style: TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: isManga ? const Color(0xFF7C57E8) : AppColors.brandBlue,
                                ),
                              ),
                            )
                          else if (epsBehind > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.statusBehind.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.statusBehind.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '$epsBehind behind',
                                style: const TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusBehind,
                                ),
                              ),
                            )
                          else if (isManga)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C57E8).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF7C57E8).withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Reading',
                                style: TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF7C57E8),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.statusWatching.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.statusWatching.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Up to date',
                                style: TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusWatching,
                                ),
                              ),
                            ),

                          // Personal Score Badge (Interactive)
                          GestureDetector(
                            onTap: onUpdateScore,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: userScore != null && userScore! > 0
                                    ? const Color(0xFFE5A158).withValues(alpha: 0.16)
                                    : AppColors.darkSurfaceInput,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: userScore != null && userScore! > 0
                                      ? const Color(0xFFE5A158).withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    userScore != null && userScore! > 0
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    size: 13,
                                    color: userScore != null && userScore! > 0
                                        ? const Color(0xFFE5A158)
                                        : AppColors.darkTextMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    userScore != null && userScore! > 0
                                        ? ScoreUtil.formatScore(userScore, format: scoreFormat)
                                        : 'Rate',
                                    style: TextStyle(
                                      fontFamily: 'Overpass',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: userScore != null && userScore! > 0
                                        ? const Color(0xFFE5A158)
                                        : AppColors.darkTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Title
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Overpass',
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 1),

                      // Subtitle
                      Text(
                        '$unitLabel $progress of ${totalUnits ?? '?'}',
                        style: const TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 10.5,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Progress Bar + Quick Increment (+1)
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            backgroundColor: AppColors.darkSurfaceInput,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      if (onIncrementProgress != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onIncrementProgress,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '+1',
                              style: TextStyle(
                                fontFamily: 'Overpass',
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                                color: isManga ? Colors.white : AppColors.darkBackground,
                              ),
                            ),
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
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    final title = TextUtil.getPreferredTitle(media['title'], preference: titlePreference);
    final coverUrl = media['coverImage']?['medium'] ?? media['coverImage']?['large'];
    final format = media['format'] as String?;
    final episodes = media['episodes'] as int? ?? media['chapters'] as int?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.p12, vertical: 2),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AppNetworkImage(
            imageUrl: coverUrl,
            width: 38,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Overpass',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        subtitle: Row(
          children: [
            if (format != null) ...[
              Text(
                format,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkTextMuted,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (userProgress != null)
              Text(
                'Prog: $userProgress / ${episodes ?? '?'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkTextSecondary,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Personal Score Badge
            GestureDetector(
              onTap: onUpdateScore,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: userScore != null && userScore! > 0
                      ? const Color(0xFFE5A158).withValues(alpha: 0.16)
                      : AppColors.darkSurfaceInput,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 12,
                      color: userScore != null && userScore! > 0 ? const Color(0xFFE5A158) : AppColors.darkTextMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      userScore != null && userScore! > 0
                          ? ScoreUtil.formatScore(userScore, format: scoreFormat)
                          : '-',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: userScore != null && userScore! > 0 ? const Color(0xFFE5A158) : AppColors.darkTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onIncrementProgress != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onIncrementProgress,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: accentColor ?? AppColors.brandBlue,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '+1',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final title = TextUtil.getPreferredTitle(media['title'], preference: titlePreference);
    final coverUrl = media['coverImage']?['large'] ?? media['coverImage']?['medium'];
    final format = media['format'] as String?;
    final color = accentColor ?? AppColors.brandBlue;

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
                if (format != null)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: FormatChip(format: format),
                  ),
                // Personal or Global Average Score badge on top right
                if ((userScore != null && userScore! > 0) || (media['averageScore'] != null && (media['averageScore'] as num) > 0))
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: userScore != null
                                ? const Color(0xFFE5A158)
                                : ((media['averageScore'] as num) >= 75
                                    ? const Color(0xFF46C07B)
                                    : const Color(0xFFE5A158)),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            userScore != null && userScore! > 0
                                ? ScoreUtil.formatScore(userScore, format: scoreFormat)
                                : '${(media['averageScore'] as num).toInt()}%',
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: userScore != null
                                  ? Colors.white
                                  : ((media['averageScore'] as num) >= 75
                                      ? const Color(0xFF46C07B)
                                      : Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Quick +1 button on bottom right of poster
                if (onIncrementProgress != null)
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: InkWell(
                      onTap: onIncrementProgress,
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Text(
                          '+1',
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Overpass',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
