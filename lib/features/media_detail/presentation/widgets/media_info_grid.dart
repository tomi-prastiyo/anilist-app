import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_util.dart';
import '../../../../core/utils/text_util.dart';

class MediaInfoGrid extends StatelessWidget {
  final Map<String, dynamic> media;

  const MediaInfoGrid({
    super.key,
    required this.media,
  });

  String _formatSource(String? source) {
    if (source == null) return '?';
    return source
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0]}${w.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  String _formatCountry(String? country) {
    switch (country?.toUpperCase()) {
      case 'JP':
        return 'Japan 🇯🇵';
      case 'KR':
        return 'South Korea 🇰🇷';
      case 'CN':
        return 'China 🇨🇳';
      case 'TW':
        return 'Taiwan 🇹🇼';
      default:
        return country ?? '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAnime = media['type'] == 'ANIME';
    final format = TextUtil.formatMediaFormat(media['format'] as String?);
    final status = TextUtil.formatMediaStatus(media['status'] as String?, isAnime: isAnime);
    final episodes = media['episodes'] as int?;
    final duration = media['duration'] as int?;
    final chapters = media['chapters'] as int?;
    final volumes = media['volumes'] as int?;
    final season = media['season'] as String?;
    final seasonYear = media['seasonYear'] as int?;
    final seasonDisplay = season != null
        ? '${TextUtil.toTitleCase(season)}${seasonYear != null ? ' $seasonYear' : ''}'
        : null;
    final startDate = DateUtil.formatFuzzyDate(media['startDate'] as Map<String, dynamic>?);
    final endDate = DateUtil.formatFuzzyDate(media['endDate'] as Map<String, dynamic>?);
    final source = _formatSource(media['source'] as String?);
    final country = _formatCountry(media['countryOfOrigin'] as String?);

    // Extract main studio and producers
    final studioEdges = (media['studios']?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    String? mainStudio;
    final List<String> producers = [];

    for (final edge in studioEdges) {
      final isMain = edge['isMain'] as bool? ?? false;
      final name = edge['node']?['name'] as String?;
      if (name == null) continue;
      if (isMain && mainStudio == null) {
        mainStudio = name;
      } else {
        producers.add(name);
      }
    }

    // Community Rankings (top ranking if available)
    final rankings = (media['rankings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    Map<String, dynamic>? topRanking;
    if (rankings.isNotEmpty) {
      topRanking = rankings.firstWhere(
        (r) => r['type'] == 'RATED',
        orElse: () => rankings.first,
      );
    }

    final items = <Map<String, String>>[
      {'label': 'Format', 'value': format.isNotEmpty ? format : '?'},
      if (episodes != null) {'label': 'Episodes', 'value': '$episodes eps'},
      if (chapters != null) {'label': 'Chapters', 'value': '$chapters chs'},
      if (volumes != null) {'label': 'Volumes', 'value': '$volumes vols'},
      if (duration != null) {'label': 'Duration', 'value': '$duration mins'},
      {'label': 'Status', 'value': status.isNotEmpty ? status : '?'},
      if (seasonDisplay != null) {'label': 'Season', 'value': seasonDisplay},
      if (startDate.isNotEmpty) {'label': 'Start Date', 'value': startDate},
      if (endDate.isNotEmpty) {'label': 'End Date', 'value': endDate},
      if (mainStudio != null) {'label': 'Main Studio', 'value': mainStudio},
      if (producers.isNotEmpty) {'label': 'Producers', 'value': producers.take(3).join(', ')},
      {'label': 'Source', 'value': source},
      {'label': 'Country', 'value': country},
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: AppSpacing.borderRadius16,
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: context.isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ranking Pill Banner (if exists)
          if (topRanking != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB703).withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFFFB703).withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 16, color: Color(0xFFFFB703)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '#${topRanking['rank']} ${topRanking['context']} ${topRanking['year'] ?? ''}',
                      style: const TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFB703),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Grid rows (exact 2-column layout using actual available width)
          Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final colWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: items.map((item) {
                    return SizedBox(
                      width: colWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['label']!,
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 11,
                              color: context.appTextMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['value']!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.appTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
