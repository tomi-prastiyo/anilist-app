import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/image/app_avatar.dart';
import '../../../profile/presentation/profile_screen.dart';

class MediaMutualFriendsCard extends StatelessWidget {
  final List<Map<String, dynamic>> friends;
  final bool isAnime;

  const MediaMutualFriendsCard({
    super.key,
    required this.friends,
    this.isAnime = true,
  });

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
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
      default:
        return AppColors.brandBlue;
    }
  }

  String _formatStatusLabel(Map<String, dynamic> item) {
    final status = (item['status'] as String? ?? '').toUpperCase();
    final progress = item['progress'] as int? ?? 0;
    final score = (item['score'] as num?)?.toDouble() ?? 0.0;

    switch (status) {
      case 'CURRENT':
        if (isAnime) {
          return progress > 0 ? 'Watching • Ep $progress' : 'Watching';
        } else {
          return progress > 0 ? 'Reading • Ch $progress' : 'Reading';
        }
      case 'COMPLETED':
        return score > 0 ? 'Completed • ${score.toStringAsFixed(0)}%' : 'Completed';
      case 'PLANNING':
        return 'Planning';
      case 'PAUSED':
        return progress > 0 ? 'Paused • $progress' : 'Paused';
      case 'DROPPED':
        return progress > 0 ? 'Dropped • $progress' : 'Dropped';
      default:
        return status.isNotEmpty ? status : 'Tracking';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      size: 16,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Following Activity',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${friends.length} friends',
                  style: const TextStyle(
                    fontFamily: 'Overpass',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal List of Friend Cards
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: friends.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final friend = friends[index];
                final user = friend['user'] as Map<String, dynamic>?;
                final userId = user?['id'] as int?;
                final userName = user?['name'] as String? ?? 'User';
                final avatarUrl = user?['avatar']?['medium'] as String?;
                final statusColor = _getStatusColor(friend['status'] as String?);
                final statusLabel = _formatStatusLabel(friend);

                return Material(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (userId != null) {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: userId),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AppAvatar(imageUrl: avatarUrl, size: 36),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.darkSurface, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
