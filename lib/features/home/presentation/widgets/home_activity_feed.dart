import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_util.dart';
import '../../../../shared/feedback/shimmer_loading.dart';
import '../../../../shared/image/app_avatar.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../activity/data/activity_repository.dart';
import '../../../activity/presentation/widgets/activity_comments_bottom_sheet.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../media_detail/presentation/media_detail_screen.dart';
import '../../../profile/presentation/profile_screen.dart';

class HomeActivityFeed extends ConsumerStatefulWidget {
  const HomeActivityFeed({super.key});

  @override
  ConsumerState<HomeActivityFeed> createState() => HomeActivityFeedState();
}

class HomeActivityFeedState extends ConsumerState<HomeActivityFeed> {
  // Default to Following (Friends Only) per user specification
  bool _isFollowing = true;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  Future<void> loadActivities() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(activityRepositoryProvider);
      final data = await repo.fetchActivities(page: 1, isFollowing: _isFollowing);
      if (mounted) {
        setState(() {
          _activities = (data['activities'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleLike(int index) async {
    HapticFeedback.lightImpact();
    final activity = _activities[index];
    final isLiked = activity['isLiked'] as bool? ?? false;
    final currentLikes = activity['likeCount'] as int? ?? 0;

    // Optimistic UI update
    setState(() {
      activity['isLiked'] = !isLiked;
      activity['likeCount'] = isLiked ? (currentLikes > 0 ? currentLikes - 1 : 0) : currentLikes + 1;
    });

    try {
      final repo = ref.read(activityRepositoryProvider);
      await repo.toggleLike(activity['id'] as int);
    } catch (e) {
      // Revert if API fails
      if (mounted) {
        setState(() {
          activity['isLiked'] = isLiked;
          activity['likeCount'] = currentLikes;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update like: ${e.toString()}'),
            backgroundColor: AppColors.statusBehind,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openComments(Map<String, dynamic> item) {
    final id = item['id'] as int?;
    if (id == null) return;
    final user = item['user'] as Map<String, dynamic>?;
    final media = item['media'] as Map<String, dynamic>?;
    final title = media != null
        ? (media['title']?['userPreferred'] as String?)
        : item['status'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityCommentsBottomSheet(
        activityId: id,
        activityUserName: user?['name'] as String?,
        activityUserAvatar: user?['avatar']?['medium'] as String?,
        activityTitle: title,
        initialReplyCount: item['replyCount'] as int? ?? 0,
        onReplyAdded: () {
          setState(() {
            item['replyCount'] = (item['replyCount'] as int? ?? 0) + 1;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final accentColor = auth is Authenticated
        ? AppColors.getProfileAccentColor(auth.user.profileColor)
        : AppColors.brandBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Segmented Pill Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COMMUNITY ACTIVITY',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),

              // Segmented Toggle: Following (Default) vs Global
              Container(
                height: 30,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceInput,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (!_isFollowing) {
                          setState(() => _isFollowing = true);
                          loadActivities();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: _isFollowing ? AppColors.darkSurface : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _isFollowing
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Following',
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _isFollowing ? Colors.white : AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_isFollowing) {
                          setState(() => _isFollowing = false);
                          loadActivities();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: !_isFollowing ? AppColors.darkSurface : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: !_isFollowing
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Global',
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: !_isFollowing ? Colors.white : AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Activity List Stream
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            child: ShimmerMediaGrid(count: 3),
          )
        else if (_activities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              alignment: Alignment.center,
              child: Text(
                _isFollowing
                    ? 'No activity from followed users yet.\nTry switching to Global above!'
                    : 'No global activity found.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 12,
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities.length.clamp(0, 15),
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _activities[index];
              final user = item['user'] as Map<String, dynamic>?;
              final avatarUrl = user?['avatar']?['medium'] as String?;
              final userName = user?['name'] as String? ?? 'Anonymous';
              final userId = user?['id'] as int?;
              final type = item['__typename'] as String?;
              final isText = type == 'TextActivity';
              final isLiked = item['isLiked'] as bool? ?? false;
              final likeCount = item['likeCount'] as int? ?? 0;
              final replyCount = item['replyCount'] as int? ?? 0;
              final createdAt = item['createdAt'] as int?;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User header (Tappable to view Profile)
                    InkWell(
                      onTap: () {
                        if (userId != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            AppAvatar(imageUrl: avatarUrl, size: 32),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: userName,
                                          style: TextStyle(
                                            fontFamily: 'Overpass',
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12.5,
                                            color: accentColor,
                                          ),
                                        ),
                                        if (!isText) ...[
                                          TextSpan(
                                            text: ' ${item['status'] ?? 'updated'}',
                                            style: const TextStyle(
                                              fontFamily: 'Overpass',
                                              fontSize: 12,
                                              color: AppColors.darkTextSecondary,
                                            ),
                                          ),
                                          if (item['progress'] != null)
                                            TextSpan(
                                              text: ' ${item['progress']}',
                                              style: const TextStyle(
                                                fontFamily: 'Overpass',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.brandBlue,
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    DateUtil.timeAgo(createdAt),
                                    style: const TextStyle(
                                      fontFamily: 'Overpass',
                                      fontSize: 10,
                                      color: AppColors.darkTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content: text or media preview
                    if (isText) ...[
                      const SizedBox(height: 8),
                      Text(
                        item['text'] as String? ?? '',
                        style: const TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                    ] else if (item['media'] != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          final mediaId = item['media']['id'] as int?;
                          if (mediaId != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MediaDetailScreen(mediaId: mediaId),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.darkBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: AppNetworkImage(
                                  imageUrl: item['media']['coverImage']?['medium'],
                                  width: 32,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  item['media']['title']?['userPreferred'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Overpass',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Action row: Functional Like + Read-Only Comment Icon
                    Row(
                      children: [
                        // Functional Like Button
                        InkWell(
                          onTap: () => _toggleLike(index),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 15,
                                  color: isLiked ? AppColors.statusBehind : AppColors.darkTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$likeCount',
                                  style: TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isLiked ? AppColors.statusBehind : AppColors.darkTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Interactive Comment Button (with count)
                        InkWell(
                          onTap: () => _openComments(item),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 14,
                                  color: AppColors.darkTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$replyCount',
                                  style: const TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
