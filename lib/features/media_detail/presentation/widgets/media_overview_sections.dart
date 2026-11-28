import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../../shared/widgets/in_app_video_dialog.dart';
import '../../../../shared/widgets/tactile_scale.dart';

class MediaRankingsStrip extends StatelessWidget {
  final List<Map<String, dynamic>> rankings;

  const MediaRankingsStrip({super.key, required this.rankings});

  @override
  Widget build(BuildContext context) {
    final topRanks = rankings.take(4).toList();
    if (topRanks.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: topRanks.map((r) {
        final rank = r['rank'] as int? ?? 0;
        final contextLabel = (r['context'] as String? ?? 'Ranked').trim();
        final year = r['year'] as int?;
        final isRated = r['type'] == 'RATED';
        final badgeColor = isRated ? const Color(0xFFFBBF24) : context.appAccent;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: context.appCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRated ? Icons.emoji_events_rounded : Icons.favorite_rounded,
                size: 14,
                color: badgeColor,
              ),
              const SizedBox(width: 6),
              Text(
                '#$rank $contextLabel${year != null ? ' $year' : ''}',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class MediaTrailerCard extends StatelessWidget {
  final Map<String, dynamic> trailer;

  const MediaTrailerCard({super.key, required this.trailer});

  @override
  Widget build(BuildContext context) {
    final id = trailer['id'] as String;
    final thumbnail = (trailer['thumbnail'] as String?)?.isNotEmpty == true
        ? trailer['thumbnail'] as String
        : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    final ytUrl = 'https://www.youtube.com/watch?v=$id';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Official Trailer',
          style: TextStyle(
            fontFamily: 'Overpass',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        TactileScale(
          onTap: () => InAppVideoDialog.show(
            context,
            url: ytUrl,
            isYoutube: true,
            accentColor: context.appAccent,
            title: 'Official Trailer',
          ),
          child: Container(
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(imageUrl: thumbnail, borderRadius: BorderRadius.zero),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: context.appAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.appAccent.withValues(alpha: 0.5),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.smart_display_rounded, color: Color(0xFFFF0000), size: 14),
                          SizedBox(width: 5),
                          Text(
                            'Watch Trailer',
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MediaTitlesCard extends StatelessWidget {
  final String? romaji;
  final String? english;
  final String? native;
  final List<String> synonyms;

  const MediaTitlesCard({
    super.key,
    this.romaji,
    this.english,
    this.native,
    this.synonyms = const [],
  });

  @override
  Widget build(BuildContext context) {
    final hasTitles = (romaji != null && romaji!.isNotEmpty) ||
        (english != null && english!.isNotEmpty) ||
        (native != null && native!.isNotEmpty) ||
        synonyms.isNotEmpty;
    if (!hasTitles) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: context.isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.appAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.translate_rounded, size: 16, color: context.appAccent),
              ),
              const SizedBox(width: 8),
              Text(
                'Alternative Titles',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (romaji != null && romaji!.isNotEmpty) _buildTitleRow(context, 'Romaji', romaji!),
          if (english != null && english!.isNotEmpty) _buildTitleRow(context, 'English', english!),
          if (native != null && native!.isNotEmpty) _buildTitleRow(context, 'Native', native!),
          if (synonyms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Synonyms',
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.appTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: synonyms
                  .map(
                    (syn) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.appBorder),
                      ),
                      child: Text(
                        syn,
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 11.5,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.appTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
