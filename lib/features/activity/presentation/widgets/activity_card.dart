import 'package:flutter/material.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/yuyuyu_assets.dart';
import '../../../../core/utils/date_util.dart';
import '../../../../shared/image/app_avatar.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../media_detail/presentation/media_detail_screen.dart';

/// Shared activity card used across both [HomeActivityFeed] and [ActivityScreen].
class ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  final Color accentColor;
  final int? currentViewerId;
  final bool compact;
  final VoidCallback onUserTap;
  final VoidCallback onLikeTap;
  final VoidCallback onLikesCountTap;
  final VoidCallback onCommentsTap;
  final VoidCallback? onDeleteTap;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.accentColor,
    required this.currentViewerId,
    required this.onUserTap,
    required this.onLikeTap,
    required this.onLikesCountTap,
    required this.onCommentsTap,
    this.onDeleteTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = activity['user'] as Map<String, dynamic>?;
    final userId = user?['id'] as int?;
    final avatarUrl = user?['avatar']?['medium'] as String?;
    final userName = user?['name'] as String? ?? 'Anonymous';
    final type = activity['__typename'] as String?;
    final isText = type == 'TextActivity';
    final isLiked = activity['isLiked'] as bool? ?? false;
    final likeCount = activity['likeCount'] as int? ?? 0;
    final replyCount = activity['replyCount'] as int? ?? 0;
    final createdAt = activity['createdAt'] as int?;
    final isOwner =
        currentViewerId != null && userId != null && userId == currentViewerId;

    final media = activity['media'] as Map<String, dynamic>?;
    final mediaId = media?['id'] as int?;
    final bannerOrCover =
        (media?['bannerImage'] ?? media?['coverImage']?['large']) as String?;
    final coverImage =
        (media?['coverImage']?['large'] ?? media?['coverImage']?['medium'])
            as String?;
    final mediaTitle = media?['title']?['userPreferred'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(
          color: compact
              ? Colors.white.withValues(alpha: 0.05)
              : context.appBorder,
        ),
        boxShadow: compact
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onUserTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  AppAvatar(imageUrl: avatarUrl, size: compact ? 32 : 36),
                  SizedBox(width: compact ? 9 : 10),
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
                                  fontSize: compact ? 12.5 : 13.5,
                                  color: compact
                                      ? accentColor
                                      : context.appTextPrimary,
                                ),
                              ),
                              if (!isText) ...[
                                TextSpan(
                                  text: ' ${activity['status'] ?? 'updated'}',
                                  style: TextStyle(
                                    fontFamily: compact ? 'Overpass' : null,
                                    fontSize: 12,
                                    color: context.appTextSecondary,
                                  ),
                                ),
                                if (activity['progress'] != null)
                                  TextSpan(
                                    text: ' ${activity['progress']}',
                                    style: TextStyle(
                                      fontFamily: compact ? 'Overpass' : null,
                                      fontSize: 12,
                                      fontWeight: compact
                                          ? FontWeight.w800
                                          : FontWeight.bold,
                                      color: compact
                                          ? (context.isYuYuYu
                                              ? YuYuYuAssets.shinjuGold
                                              : AppColors.brandBlue)
                                          : accentColor,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (compact) const SizedBox(height: 1),
                        Text(
                          DateUtil.timeAgo(createdAt),
                          style: TextStyle(
                            fontFamily: compact ? 'Overpass' : null,
                            fontSize: compact ? 10 : 10.5,
                            color: context.appTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwner && onDeleteTap != null)
                    IconButton(
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(28, 28),
                        padding: EdgeInsets.zero,
                      ),
                      constraints:
                          const BoxConstraints.tightFor(width: 28, height: 28),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: context.appTextMuted,
                      ),
                      tooltip: 'Delete activity',
                      onPressed: onDeleteTap,
                    ),
                ],
              ),
            ),
          ),

          if (isText) ...[
            const SizedBox(height: 8),
            Text(
              activity['text'] as String? ?? '',
              style: TextStyle(
                fontFamily: compact ? 'Overpass' : null,
                fontSize: compact ? 12.5 : 13,
                height: compact ? 1.35 : 1.4,
                color: context.appTextPrimary,
              ),
            ),
          ] else if (media != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: mediaId == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        AppPageRoute(
                          page: MediaDetailScreen(mediaId: mediaId),
                        ),
                      );
                    },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: compact ? 76 : 74,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: context.appBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.appBorder),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (bannerOrCover != null)
                      Opacity(
                        opacity: context.isDark ? 0.22 : 0.12,
                        child: AppNetworkImage(
                          imageUrl: bannerOrCover,
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
                            context.appBackground.withValues(alpha: 0.92),
                            context.appBackground.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: AppNetworkImage(
                              imageUrl: coverImage,
                              width: 44,
                              height: compact ? 64 : 62,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mediaTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Overpass',
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: context.appTextPrimary,
                              ),
                            ),
                          ),
                          if (!compact)
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: context.appTextMuted,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: compact ? 8 : 10),

          Row(
            children: [
              Container(
                decoration: compact
                    ? null
                    : BoxDecoration(
                        color: isLiked
                            ? AppColors.statusBehind.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(6),
                      ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onLikeTap,
                      borderRadius: compact
                          ? BorderRadius.circular(4)
                          : const BorderRadius.horizontal(
                              left: Radius.circular(6)),
                      child: Padding(
                        padding: compact
                            ? const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2)
                            : const EdgeInsets.fromLTRB(8, 4, 4, 4),
                        child: Icon(
                          isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: compact ? 15 : 16,
                          color: isLiked
                              ? AppColors.statusBehind
                              : context.appTextSecondary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onLikesCountTap,
                      borderRadius: compact
                          ? BorderRadius.circular(4)
                          : const BorderRadius.horizontal(
                              right: Radius.circular(6)),
                      child: Padding(
                        padding: compact
                            ? const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2)
                            : const EdgeInsets.fromLTRB(2, 4, 8, 4),
                        child: Text(
                          '$likeCount',
                          style: TextStyle(
                            fontFamily: compact ? 'Overpass' : null,
                            fontSize: compact ? 11 : 12,
                            fontWeight:
                                compact ? FontWeight.w700 : FontWeight.bold,
                            color: isLiked
                                ? AppColors.statusBehind
                                : context.appTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 14 : 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(compact ? 4 : 16),
                  onTap: onCommentsTap,
                  child: Padding(
                    padding: compact
                        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                        : const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: compact ? 14 : 15,
                          color: context.appTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          compact
                              ? '$replyCount'
                              : (replyCount > 0 ? '$replyCount' : 'Reply'),
                          style: TextStyle(
                            fontFamily: compact ? 'Overpass' : null,
                            fontSize: compact ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
