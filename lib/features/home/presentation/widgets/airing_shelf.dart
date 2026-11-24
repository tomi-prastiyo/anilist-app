import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_util.dart';
import '../../../../core/utils/text_util.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../media_detail/presentation/media_detail_screen.dart';
import '../airing_schedule_screen.dart';

class AiringShelf extends StatelessWidget {
  final List<Map<String, dynamic>> schedules;

  const AiringShelf({super.key, required this.schedules});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) return const SizedBox.shrink();

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
                      color: AppColors.statusBehind,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AIRING TODAY & SOON',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      color: Colors.white,
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
                      builder: (context) => const AiringScheduleScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Schedule →',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      color: AppColors.brandBlue,
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

        // Horizontal Carousel
        SizedBox(
          height: 172,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            scrollDirection: Axis.horizontal,
            itemCount: schedules.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              final media = schedule['media'] as Map<String, dynamic>?;
              final title = TextUtil.getPreferredTitle(media?['title']);
              final cover = (media?['coverImage']?['large'] ?? media?['coverImage']?['medium']) as String?;
              final episode = schedule['episode'] as int? ?? 1;
              final timeUntil = schedule['timeUntilAiring'] as int?;
              final countdownText = DateUtil.formatCountdown(timeUntil);

              return GestureDetector(
                onTap: () {
                  final id = media?['id'] as int?;
                  if (id != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MediaDetailScreen(mediaId: id),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  padding: const EdgeInsets.all(7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover image with countdown badge
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: AppNetworkImage(
                              imageUrl: cover,
                              width: 116,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.statusBehind,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: Text(
                                'Ep $episode in $countdownText',
                                style: const TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Title
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Overpass',
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Episode $episode Airing',
                        style: const TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 10,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
