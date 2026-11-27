import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/anilist_bio_widget.dart';

class ProfileStatsTab extends StatefulWidget {
  final String? about;
  final String? aboutHtml;
  final int animeCount;
  final String animeDays;
  final double animeMeanScore;
  final double animeStdDev;
  final int animeEpisodes;
  final int animeMinutes;
  final List<Map<String, dynamic>> animeStatuses;
  final List<Map<String, dynamic>> animeScores;
  final List<Map<String, dynamic>> animeFormats;
  final List<Map<String, dynamic>> animeGenres;
  final int mangaCount;
  final int mangaChapters;
  final int mangaVolumes;
  final double mangaMeanScore;
  final List<Map<String, dynamic>> mangaStatuses;
  final List<Map<String, dynamic>> mangaScores;
  final List<Map<String, dynamic>> mangaGenres;
  final Color accentColor;
  final bool isOwn;
  final Future<bool> Function(String newBio)? onSaveBio;

  const ProfileStatsTab({
    super.key,
    this.about,
    this.aboutHtml,
    required this.animeCount,
    required this.animeDays,
    required this.animeMeanScore,
    required this.animeStdDev,
    required this.animeEpisodes,
    required this.animeMinutes,
    required this.animeStatuses,
    required this.animeScores,
    required this.animeFormats,
    required this.animeGenres,
    required this.mangaCount,
    required this.mangaChapters,
    required this.mangaVolumes,
    required this.mangaMeanScore,
    required this.mangaStatuses,
    required this.mangaScores,
    required this.mangaGenres,
    required this.accentColor,
    required this.isOwn,
    this.onSaveBio,
  });

  @override
  State<ProfileStatsTab> createState() => _ProfileStatsTabState();
}

class _ProfileStatsTabState extends State<ProfileStatsTab> {
  String _statsMode = 'ANIME'; // 'ANIME' or 'MANGA'

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.p16,
        AppSpacing.p16,
        AppSpacing.p16,
        24,
      ),
      children: [
        // 1. Expandable About Bio Card
        AniListBioWidget(
          bio: widget.about,
          bioHtml: widget.aboutHtml,
          accentColor: accentColor,
          isOwn: widget.isOwn,
          onSaveBio: widget.onSaveBio,
        ),

        // 2. Segmented Pill Switch: Anime Stats vs Manga Stats
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeToggle(
                  label: 'Anime Stats',
                  icon: Icons.tv_rounded,
                  selected: _statsMode == 'ANIME',
                  accentColor: accentColor,
                  onTap: () => setState(() => _statsMode = 'ANIME'),
                ),
                _buildModeToggle(
                  label: 'Manga Stats',
                  icon: Icons.menu_book_rounded,
                  selected: _statsMode == 'MANGA',
                  accentColor: accentColor,
                  onTap: () => setState(() => _statsMode = 'MANGA'),
                ),
              ],
            ),
          ),
        ),

        if (_statsMode == 'ANIME') ...[
          Row(
            children: [
              _statCard(context, 'Total Anime', '${widget.animeCount}', Icons.tv_rounded, accentColor, const Color(0xFF3DB4F2)),
              const SizedBox(width: 8),
              _statCard(context, 'Days Watched', '${widget.animeDays}d', Icons.access_time_rounded, accentColor, const Color(0xFF00B4D8)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statCard(context, 'Mean Score', widget.animeMeanScore > 0 ? '${widget.animeMeanScore.toStringAsFixed(1)}%' : '-', Icons.star_rounded, accentColor, const Color(0xFFFFB703)),
              const SizedBox(width: 8),
              _statCard(context, 'Std Dev', widget.animeStdDev > 0 ? widget.animeStdDev.toStringAsFixed(1) : '-', Icons.query_stats_rounded, accentColor, const Color(0xFFE056FD)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statCard(context, 'Episodes', '${widget.animeEpisodes}', Icons.play_circle_outline_rounded, accentColor, const Color(0xFF06D6A0)),
              const SizedBox(width: 8),
              _statCard(context, 'Time Watched', '${(widget.animeMinutes / 60).toStringAsFixed(0)}h', Icons.timer_outlined, accentColor, const Color(0xFF9D4EDD)),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.animeStatuses.isNotEmpty)
            _buildStatusBar(context, widget.animeStatuses, accentColor, isAnime: true),
          if (widget.animeScores.isNotEmpty)
            _buildScoreHistogram(context, widget.animeScores, widget.animeMeanScore, accentColor),
          if (widget.animeFormats.isNotEmpty)
            _buildFormatDonut(context, widget.animeFormats, widget.animeCount, accentColor),
          if (widget.animeGenres.isNotEmpty)
            _buildGenresVisualizer(context, widget.animeGenres, accentColor),
        ] else ...[
          Row(
            children: [
              _statCard(context, 'Total Manga', '${widget.mangaCount}', Icons.menu_book_rounded, accentColor, const Color(0xFF3DB4F2)),
              const SizedBox(width: 8),
              _statCard(context, 'Chapters Read', '${widget.mangaChapters}', Icons.auto_stories_rounded, accentColor, const Color(0xFF00B4D8)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statCard(context, 'Volumes Read', '${widget.mangaVolumes}', Icons.book_rounded, accentColor, const Color(0xFF06D6A0)),
              const SizedBox(width: 8),
              _statCard(context, 'Mean Score', widget.mangaMeanScore > 0 ? '${widget.mangaMeanScore.toStringAsFixed(1)}%' : '-', Icons.star_rounded, accentColor, const Color(0xFFFFB703)),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.mangaStatuses.isNotEmpty)
            _buildStatusBar(context, widget.mangaStatuses, accentColor, isAnime: false),
          if (widget.mangaScores.isNotEmpty)
            _buildScoreHistogram(context, widget.mangaScores, widget.mangaMeanScore, accentColor),
          if (widget.mangaGenres.isNotEmpty)
            _buildGenresVisualizer(context, widget.mangaGenres, accentColor),
        ],
      ],
    );
  }

  Widget _buildModeToggle({
    required String label,
    required IconData icon,
    required bool selected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : context.appTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : context.appTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(
    BuildContext context,
    List<Map<String, dynamic>> statuses,
    Color accentColor, {
    required bool isAnime,
  }) {
    final total = statuses.fold<int>(0, (sum, item) => sum + (item['count'] as int? ?? 0));
    if (total == 0) return const SizedBox.shrink();

    Color getStatusColor(String status) {
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
          return AppColors.statusRepeating;
        default:
          return AppColors.brandBlue;
      }
    }

    String getStatusLabel(String status) {
      switch (status.toUpperCase()) {
        case 'CURRENT':
          return isAnime ? 'Watching' : 'Reading';
        case 'COMPLETED':
          return 'Completed';
        case 'PLANNING':
          return 'Planning';
        case 'PAUSED':
          return 'Paused';
        case 'DROPPED':
          return 'Dropped';
        case 'REPEATING':
          return isAnime ? 'Rewatching' : 'Rereading';
        default:
          return status;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.donut_small_rounded, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Text(
                'Status Distribution',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$total entries',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: statuses.map((s) {
                  final cnt = s['count'] as int? ?? 0;
                  final status = s['status'] as String? ?? '';
                  final pct = cnt / total;
                  return Expanded(
                    flex: (pct * 1000).toInt().clamp(1, 1000),
                    child: Container(color: getStatusColor(status)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: statuses.map((s) {
              final cnt = s['count'] as int? ?? 0;
              final status = s['status'] as String? ?? '';
              final color = getStatusColor(status);
              final label = getStatusLabel(status);
              final pct = ((cnt / total) * 100).toStringAsFixed(1);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$label ($cnt • $pct%)',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHistogram(
    BuildContext context,
    List<Map<String, dynamic>> scoreList,
    double meanScore,
    Color accentColor,
  ) {
    final sortedScores = List<Map<String, dynamic>>.from(scoreList)
      ..sort((a, b) => ((a['score'] as num?) ?? 0).compareTo((b['score'] as num?) ?? 0));
    final maxCount = sortedScores
        .map((e) => (e['count'] as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    Color barColorForScore(num score) {
      if (score >= 75) return AppColors.scoreHigh;
      if (score >= 60) return AppColors.scoreMedium;
      return AppColors.scoreLow;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.bar_chart_rounded, size: 16, color: accentColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Score Distribution',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  meanScore > 0 ? 'Avg: ${meanScore.toStringAsFixed(1)}%' : '10 – 100',
                  style: TextStyle(
                    fontFamily: 'Overpass',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount * 1.25 + 2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => context.appCard,
                    tooltipRoundedRadius: 6,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final score = sortedScores[group.x]['score'];
                      final count = rod.toY.toInt();
                      return BarTooltipItem(
                        '$score%: $count titles',
                        TextStyle(
                          color: context.appTextPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < sortedScores.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${sortedScores[idx]['score']}',
                              style: TextStyle(
                                fontFamily: 'Overpass',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: context.appTextSecondary,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: sortedScores.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final scoreVal = (entry.value['score'] as num?) ?? 0;
                  final countVal = (entry.value['count'] as num).toDouble();
                  final barColor = barColorForScore(scoreVal);
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: countVal,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            barColor.withValues(alpha: 0.65),
                            barColor,
                          ],
                        ),
                        width: 15,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatDonut(
    BuildContext context,
    List<Map<String, dynamic>> formatList,
    int totalCount,
    Color accentColor,
  ) {
    Color getFormatColor(String format) {
      switch (format.toUpperCase()) {
        case 'TV':
          return const Color(0xFF3DB4F2);
        case 'TV_SHORT':
          return const Color(0xFF00B4D8);
        case 'MOVIE':
          return AppColors.statusCompleted;
        case 'OVA':
          return AppColors.statusPaused;
        case 'ONA':
          return const Color(0xFF9D4EDD);
        case 'SPECIAL':
          return AppColors.statusPlanning;
        case 'MANGA':
          return AppColors.statusRepeating;
        default:
          return accentColor;
      }
    }

    final topFormats = formatList.take(6).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.pie_chart_outline_rounded, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Text(
                'Format Breakdown',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              height: 160,
              width: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 46,
                      sections: topFormats.map((f) {
                        final format = f['format'] as String? ?? '';
                        final cnt = (f['count'] as num?)?.toDouble() ?? 0.0;
                        return PieChartSectionData(
                          value: cnt,
                          showTitle: false,
                          radius: 30,
                          color: getFormatColor(format),
                        );
                      }).toList(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalCount',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        'TITLES',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: context.appTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: topFormats.map((f) {
              final format = f['format'] as String? ?? '';
              final cnt = f['count'] as int? ?? 0;
              final color = getFormatColor(format);
              final pct = totalCount > 0 ? ((cnt / totalCount) * 100).toStringAsFixed(1) : '0';

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$format ($cnt • $pct%)',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenresVisualizer(
    BuildContext context,
    List<Map<String, dynamic>> genreList,
    Color accentColor,
  ) {
    final maxCnt = (genreList.first['count'] as num?)?.toDouble() ?? 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.category_rounded, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Text(
                'Top Genres',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...genreList.take(7).map((g) {
            final genre = g['genre'] as String? ?? '';
            final cnt = g['count'] as int? ?? 0;
            final progress = (cnt / maxCnt).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        genre,
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        '$cnt entries',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: context.appBorder,
                      color: accentColor,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color accentColor, [
    Color? iconColor,
  ]) {
    final effectiveColor = iconColor ?? accentColor;
    final match = RegExp(r'^(\d+(?:\.\d+)?)(.*)$').firstMatch(value.trim());
    final parsedTarget = match != null ? double.tryParse(match.group(1)!) : null;
    final decimals =
        match != null && match.group(1)!.contains('.') ? match.group(1)!.split('.').last.length : 0;
    final suffix = match?.group(2) ?? '';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 15, color: effectiveColor),
            ),
            const SizedBox(height: 6),
            if (parsedTarget != null)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: parsedTarget),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) {
                  final formatted = decimals > 0
                      ? animatedValue.toStringAsFixed(decimals)
                      : animatedValue.round().toString();
                  return Text(
                    '$formatted$suffix',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: context.appTextPrimary,
                    ),
                  );
                },
              )
            else
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: context.appTextPrimary,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.appTextSecondary,
              ),
            ),
          ],
        ),
      ).animateEntrance(),
    );
  }
}
