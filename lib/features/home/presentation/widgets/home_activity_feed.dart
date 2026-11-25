import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_util.dart';
import '../../../../shared/feedback/shimmer_loading.dart';
import '../../../../shared/image/app_avatar.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../activity/data/activity_repository.dart';
import '../../../activity/presentation/widgets/activity_comments_bottom_sheet.dart';
import '../../../activity/presentation/widgets/activity_likes_bottom_sheet.dart';
import '../../../activity/presentation/widgets/delete_activity_dialog.dart';
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
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNextPage = true;
  List<Map<String, dynamic>> _activities = [];
  final Set<int> _togglingLikeIds = {};

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  Future<void> loadActivities({int page = 1, bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasNextPage = true;
      });
    }
    try {
      final repo = ref.read(activityRepositoryProvider);
      final data = await repo.fetchActivities(page: page, isFollowing: _isFollowing);
      final pageInfo = data['pageInfo'] as Map<String, dynamic>?;
      final list = (data['activities'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) {
        setState(() {
          if (reset) {
            _activities = list;
          } else {
            _activities.addAll(list);
          }
          _currentPage = page;
          _hasNextPage = pageInfo?['hasNextPage'] as bool? ?? false;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreActivities() async {
    if (_isLoadingMore || !_hasNextPage) return;
    HapticFeedback.lightImpact();
    setState(() => _isLoadingMore = true);
    await loadActivities(page: _currentPage + 1, reset: false);
  }

  Future<void> _deleteActivity(int index) async {
    final activity = _activities[index];
    final id = activity['id'] as int?;
    if (id == null) return;

    final confirmed = await showDeleteActivityConfirmDialog(context);
    if (!confirmed || !mounted) return;

    final removed = _activities[index];
    setState(() => _activities.removeAt(index));

    try {
      final ok = await ref.read(activityRepositoryProvider).deleteActivity(id);
      if (!ok) throw Exception('Failed to delete');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity deleted'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _activities.insert(index.clamp(0, _activities.length), removed));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete activity: $e'), backgroundColor: AppColors.statusDropped),
        );
      }
    }
  }

  Future<void> _toggleLike(int index) async {
    final isAuthenticated = ref.read(authControllerProvider) is Authenticated;
    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in with AniList to like activities.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final activity = _activities[index];
    final activityId = activity['id'] as int?;
    if (activityId == null || _togglingLikeIds.contains(activityId)) return;

    HapticFeedback.lightImpact();
    _togglingLikeIds.add(activityId);
    final isLiked = activity['isLiked'] as bool? ?? false;
    final currentLikes = activity['likeCount'] as int? ?? 0;
    final optimisticLiked = !isLiked;
    final optimisticCount = isLiked ? (currentLikes > 0 ? currentLikes - 1 : 0) : currentLikes + 1;

    // Optimistic UI update
    setState(() {
      activity['isLiked'] = optimisticLiked;
      activity['likeCount'] = optimisticCount;
    });

    try {
      final repo = ref.read(activityRepositoryProvider);
      final updated = await repo.toggleLike(activityId);
      if (mounted) {
        final finalLiked = updated?['isLiked'] as bool? ?? optimisticLiked;
        final finalCount = updated?['likeCount'] as int? ?? optimisticCount;
        setState(() {
          activity['isLiked'] = finalLiked;
          activity['likeCount'] = finalCount;
        });
        ref.read(activityLikeSyncProvider.notifier).state = (
          id: activityId,
          isLiked: finalLiked,
          likeCount: finalCount,
        );
      }
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
    } finally {
      _togglingLikeIds.remove(activityId);
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
        media: media,
        activityStatus: item['status'] as String?,
        activityProgress: item['progress'] != null ? '${item['progress']}' : null,
        initialReplyCount: item['replyCount'] as int? ?? 0,
        onReplyAdded: () {
          setState(() {
            item['replyCount'] = (item['replyCount'] as int? ?? 0) + 1;
          });
        },
      ),
    );
  }

  void _openLikes(Map<String, dynamic> item) {
    final id = item['id'] as int?;
    if (id == null) return;
    final user = item['user'] as Map<String, dynamic>?;
    final media = item['media'] as Map<String, dynamic>?;
    final rawLikes = item['likes'] as List?;
    final initialLikes = rawLikes?.cast<Map<String, dynamic>>() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityLikesBottomSheet(
        activityId: id,
        media: media,
        activityStatus: item['status'] as String?,
        activityProgress: item['progress'] != null ? '${item['progress']}' : null,
        activityUserName: user?['name'] as String?,
        initialLikes: initialLikes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final accentColor = auth is Authenticated
        ? AppColors.getProfileAccentColor(auth.user.profileColor)
        : AppColors.brandBlue;

    ref.listen<({int id, bool isLiked, int likeCount})?>(
      activityLikeSyncProvider,
      (_, next) {
        if (next == null || !mounted) return;
        final idx = _activities.indexWhere((a) => a['id'] == next.id);
        if (idx != -1 &&
            (_activities[idx]['isLiked'] != next.isLiked ||
                _activities[idx]['likeCount'] != next.likeCount)) {
          setState(() {
            _activities[idx]['isLiked'] = next.isLiked;
            _activities[idx]['likeCount'] = next.likeCount;
          });
        }
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Segmented Pill Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.appAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ACTIVITY',
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Overpass',
                  color: context.appTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),

              // Segmented Toggle: Following (Default) vs Global
              Container(
                height: 28,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: context.appInputSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.appBorder),
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
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(
                          color: _isFollowing ? context.appSurface : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _isFollowing
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.08),
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
                            color: _isFollowing ? context.appTextPrimary : context.appTextSecondary,
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
                          color: !_isFollowing ? context.appSurface : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: !_isFollowing
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.08),
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
                            color: !_isFollowing ? context.appTextPrimary : context.appTextSecondary,
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
                color: context.appSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              alignment: Alignment.center,
              child: Text(
                _isFollowing
                    ? 'No activity from followed users yet.\nTry switching to Global above!'
                    : 'No global activity found.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 12,
                  color: context.appTextSecondary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities.length,
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
                  color: context.appSurface,
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
                                            style: TextStyle(
                                              fontFamily: 'Overpass',
                                              fontSize: 12,
                                              color: context.appTextSecondary,
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
                                      style: TextStyle(
                                        fontFamily: 'Overpass',
                                        fontSize: 10,
                                        color: context.appTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (auth is Authenticated && userId != null && userId == auth.user.id)
                                IconButton(
                                  style: IconButton.styleFrom(
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    minimumSize: const Size(28, 28),
                                    padding: EdgeInsets.zero,
                                  ),
                                  constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 16,
                                    color: context.appTextMuted,
                                  ),
                                  tooltip: 'Delete activity',
                                  onPressed: () => _deleteActivity(index),
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
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 12.5,
                          height: 1.35,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ] else if (item['media'] != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          final mediaId = item['media']['id'] as int?;
                          if (mediaId != null) {
                            Navigator.of(context).push(
                              AppPageRoute(page: MediaDetailScreen(mediaId: mediaId)),
                            );
                          }
                        },
                        child: Container(
                          height: 76,
                          decoration: BoxDecoration(
                            color: context.appBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.appBorder),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if ((item['media']['bannerImage'] ?? item['media']['coverImage']?['large']) != null)
                                Opacity(
                                  opacity: context.isDark ? 0.22 : 0.12,
                                  child: AppNetworkImage(
                                    imageUrl: item['media']['bannerImage'] ?? item['media']['coverImage']?['large'],
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
                                        imageUrl: item['media']['coverImage']?['large'] ??
                                            item['media']['coverImage']?['medium'],
                                        width: 44,
                                        height: 64,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item['media']['title']?['userPreferred'] ?? '',
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
                                  ],
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
                        // Functional Like + View Likes Counter
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _toggleLike(index),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Icon(
                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 15,
                                  color: isLiked ? AppColors.statusBehind : context.appTextSecondary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _openLikes(item),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  '$likeCount',
                                  style: TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isLiked ? AppColors.statusBehind : context.appTextSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 14,
                                  color: context.appTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$replyCount',
                                  style: TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: context.appTextSecondary,
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
        if (_activities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: 12),
            child: _hasNextPage
                ? SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoadingMore ? null : _loadMoreActivities,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: context.appSurface,
                        side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoadingMore
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentColor,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.expand_more_rounded, size: 18, color: accentColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Load More Activities',
                                  style: TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No more community activities ✨',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: context.appTextSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}
