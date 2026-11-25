import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/score_util.dart';
import '../../core/utils/text_util.dart';
import '../badges/format_chip.dart';
import '../image/app_network_image.dart';
import '../widgets/media_progress_bar.dart';
import '../widgets/progress_increment_pills.dart';
import '../widgets/tactile_scale.dart';

enum MediaCardMode { grid, list, compact }

class MediaCard extends StatelessWidget {
  final Map<String, dynamic> media;
  final MediaCardMode mode;
  final VoidCallback? onTap;
  final VoidCallback? onIncrementProgress;
  final VoidCallback? onIncrementVolume;
  final VoidCallback? onUpdateScore;
  final int? userProgress;
  final int? userVolumeProgress;
  final double? userScore;
  final String scoreFormat;
  final String titlePreference;
  final Color? accentColor;
  final String? listStatus;
  final String? inListBadge;

  const MediaCard({
    super.key,
    required this.media,
    this.mode = MediaCardMode.list,
    this.onTap,
    this.onIncrementProgress,
    this.onIncrementVolume,
    this.onUpdateScore,
    this.userProgress,
    this.userVolumeProgress,
    this.userScore,
    this.scoreFormat = 'POINT_100',
    this.titlePreference = 'ROMAJI',
    this.accentColor,
    this.listStatus,
    this.inListBadge,
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
    final coverUrl = media['coverImage']?['extraLarge'] ??
        media['coverImage']?['large'] ??
        media['coverImage']?['medium'];
    final bannerUrl = media['bannerImage'] as String?;
    final backdrop = bannerUrl ?? coverUrl;
    final format = media['format'] as String? ?? 'TV';
    final episodes = media['episodes'] as int?;
    final chapters = media['chapters'] as int?;
    final totalUnits = episodes ?? chapters;
    final progress = userProgress ?? 0;

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

    return TactileScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appBorder),
          boxShadow: [
            BoxShadow(
              color: context.isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (backdrop != null)
              Positioned.fill(
                child: Opacity(
                  opacity: context.isDark ? 0.14 : 0.07,
                  child: AppNetworkImage(
                    imageUrl: backdrop,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      context.appSurface.withValues(alpha: 0.94),
                      context.appSurface.withValues(alpha: 0.76),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover Image with Format Pill
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: AppNetworkImage(
                            imageUrl: coverUrl,
                            width: 72,
                            height: 102,
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
                            // Top Row: Global Average Score + Status Pill (Wrap prevents collision)
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (avgScore != null && avgScore > 0)
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
                                          style: AppTypography.style(
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
                                if (status != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: status == 'RELEASING'
                                          ? const Color(0xFF46C07B).withValues(alpha: 0.12)
                                          : context.appAccent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      TextUtil.formatMediaStatus(status, isAnime: !isManga).toUpperCase(),
                                      style: AppTypography.style(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: status == 'RELEASING' ? const Color(0xFF46C07B) : context.appAccent,
                                      ),
                                    ),
                                  ),
                                if (inListBadge != null && inListBadge!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: _badgeColorForListStatus(inListBadge!).withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _badgeColorForListStatus(inListBadge!).withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Text(
                                      _formatInListShort(inListBadge!),
                                      style: AppTypography.style(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: _badgeColorForListStatus(inListBadge!),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            // Title
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.style(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                height: 1.16,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Metadata (Episodes/Chapters • Year)
                            Text(
                              [
                                if (episodes != null) '$episodes eps' else if (chapters != null) '$chapters ch',
                                if (year != null) '$year',
                              ].join(' • '),
                              style: TextStyle(
                                fontFamily: 'Overpass',
                                fontSize: 10.5,
                                color: context.appTextSecondary,
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
                                    color: context.appInputSurface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: context.appBorder),
                                  ),
                                  child: Text(
                                    g,
                                    style: TextStyle(
                                      fontFamily: 'Overpass',
                                      fontSize: 9,
                                      color: context.appTextSecondary,
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
                                    : context.appInputSurface,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: userScore != null && userScore! > 0
                                      ? const Color(0xFFE5A158).withValues(alpha: 0.4)
                                      : context.appBorder,
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
                                        : context.appTextMuted,
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
                                          : context.appTextMuted,
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

                      // Subtitle
                      Text(
                        (isManga && userVolumeProgress != null)
                            ? 'Ch $progress/${totalUnits ?? '?'} • Vol $userVolumeProgress/${media['volumes'] ?? '?'}'
                            : '$unitLabel $progress of ${totalUnits ?? '?'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 10.5,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Progress Bar + Quick Increment (+1 / +Ch & +Vol)
                  Row(
                    children: [
                      Expanded(
                        child: MediaProgressBar(
                          progress: progress,
                          total: totalUnits,
                          color: color,
                        ),
                      ),
                        if (onIncrementProgress != null) ...[
                          const SizedBox(width: 8),
                          ProgressIncrementPills(
                            accentColor: color,
                            primaryTextColor: color.computeLuminance() > 0.55
                                ? AppColors.darkBackground
                                : Colors.white,
                            onIncrementPrimary: onIncrementProgress!,
                            onIncrementVolume: onIncrementVolume,
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
    final color = accentColor ?? AppColors.brandBlue;

    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AppNetworkImage(
                  imageUrl: coverUrl,
                  width: 40,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.style(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (format != null) ...[
                          Text(
                            format,
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: context.appTextMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (userProgress != null)
                          Expanded(
                            child: Text(
                              (userVolumeProgress != null &&
                                      (media['chapters'] != null || media['type'] == 'MANGA'))
                                  ? 'Ch $userProgress/${episodes ?? '?'} • Vol $userVolumeProgress/${media['volumes'] ?? '?'}'
                                  : 'Prog: $userProgress / ${episodes ?? '?'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Overpass',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onUpdateScore,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: userScore != null && userScore! > 0
                        ? const Color(0xFFE5A158).withValues(alpha: 0.16)
                        : context.appInputSurface,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: userScore != null && userScore! > 0
                          ? const Color(0xFFE5A158).withValues(alpha: 0.35)
                          : context.appBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: userScore != null && userScore! > 0 ? const Color(0xFFE5A158) : context.appTextMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        userScore != null && userScore! > 0
                            ? ScoreUtil.formatScore(userScore, format: scoreFormat)
                            : '-',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: userScore != null && userScore! > 0 ? const Color(0xFFE5A158) : context.appTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (onIncrementProgress != null) ...[
                const SizedBox(width: 6),
                ProgressIncrementPills(
                  accentColor: color,
                  primaryTextColor: color.computeLuminance() > 0.55
                      ? AppColors.darkBackground
                      : Colors.white,
                  compact: true,
                  onIncrementPrimary: onIncrementProgress!,
                  onIncrementVolume: onIncrementVolume,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final title = TextUtil.getPreferredTitle(media['title'], preference: titlePreference);
    final coverUrl = media['coverImage']?['extraLarge'] ??
        media['coverImage']?['large'] ??
        media['coverImage']?['medium'];
    final format = media['format'] as String?;
    final color = accentColor ?? context.appAccent;

    return TactileScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: context.appBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(
              imageUrl: coverUrl,
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
            // Smooth bottom artwork overlay so poster fills 100% of card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.42, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.20),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
            // Non-overlapping Top Badges Row
            if (format != null ||
                (userScore != null && userScore! > 0) ||
                (media['averageScore'] != null && (media['averageScore'] as num) > 0))
              Positioned(
                top: 7,
                left: 7,
                right: 7,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (format != null)
                      Flexible(
                        child: FormatChip(format: format, fontSize: 8.5),
                      )
                    else
                      const SizedBox.shrink(),
                    if ((userScore != null && userScore! > 0) ||
                        (media['averageScore'] != null && (media['averageScore'] as num) > 0)) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 11,
                              color: userScore != null && userScore! > 0
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
                              style: AppTypography.style(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: userScore != null && userScore! > 0
                                    ? Colors.white
                                    : ((media['averageScore'] as num) >= 75
                                        ? const Color(0xFF46C07B)
                                        : Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            // Bottom title & optional quick +1 button
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (inListBadge != null && inListBadge!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
                        decoration: BoxDecoration(
                          color: _badgeColorForListStatus(inListBadge!).withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatInListShort(inListBadge!),
                          style: AppTypography.style(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.style(
                            fontSize: 12,
                            height: 1.16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                      ),
                      if (onIncrementProgress != null) ...[
                        const SizedBox(width: 6),
                        ProgressIncrementPills(
                          accentColor: color,
                          primaryTextColor: color.computeLuminance() > 0.55
                              ? AppColors.darkBackground
                              : Colors.white,
                          compact: true,
                          stacked: onIncrementVolume != null,
                          onIncrementPrimary: onIncrementProgress!,
                          onIncrementVolume: onIncrementVolume,
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

  static Color _badgeColorForListStatus(String status) {
    switch (status.toUpperCase()) {
      case 'CURRENT':
        return AppColors.statusWatching;
      case 'COMPLETED':
        return AppColors.statusCompleted;
      case 'PLANNING':
        return AppColors.statusPlanning;
      case 'PAUSED':
        return AppColors.statusPaused;
      case 'DROPPED':
        return AppColors.statusDropped;
      case 'REPEATING':
        return const Color(0xFF7C57E8);
      default:
        return AppColors.brandBlue;
    }
  }

  static String _formatInListShort(String status) {
    switch (status.toUpperCase()) {
      case 'CURRENT':
        return 'WATCHING';
      case 'COMPLETED':
        return 'DONE';
      case 'PLANNING':
        return 'PLAN';
      case 'PAUSED':
        return 'PAUSED';
      case 'DROPPED':
        return 'DROPPED';
      case 'REPEATING':
        return 'REPEAT';
      default:
        return status.toUpperCase();
    }
  }
}
