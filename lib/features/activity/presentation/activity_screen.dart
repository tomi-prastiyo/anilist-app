import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_util.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/image/app_avatar.dart';
import '../../../shared/image/app_network_image.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/activity_repository.dart';
import 'widgets/activity_comments_bottom_sheet.dart';
import 'widgets/activity_likes_bottom_sheet.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  final int? userId;
  final bool isEmbedded;

  const ActivityScreen({
    super.key,
    this.userId,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  bool _isFollowing = true; // Default: Friends Only
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNextPage = true;

  @override
  void initState() {
    super.initState();
    _load(page: 1);
  }

  @override
  void didUpdateWidget(covariant ActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _load(page: 1);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load({required int page, bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
      });
    } else {
      if (_isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final repo = ref.read(activityRepositoryProvider);
      final pageData = await repo.fetchActivities(
        page: page,
        userId: widget.userId,
        isFollowing: widget.userId == null ? _isFollowing : null,
      );
      final pageInfo = pageData['pageInfo'] as Map<String, dynamic>?;
      final list = (pageData['activities'] as List?)?.cast<Map<String, dynamic>>() ?? [];

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

  Future<void> _toggleLike(int index) async {
    HapticFeedback.lightImpact();
    final activity = _activities[index];
    final isLiked = activity['isLiked'] as bool? ?? false;
    final currentLikes = activity['likeCount'] as int? ?? 0;

    setState(() {
      activity['isLiked'] = !isLiked;
      activity['likeCount'] = isLiked ? (currentLikes > 0 ? currentLikes - 1 : 0) : currentLikes + 1;
    });

    try {
      final repo = ref.read(activityRepositoryProvider);
      await repo.toggleLike(activity['id'] as int);
    } catch (_) {
      // Revert if error
      if (mounted) {
        setState(() {
          activity['isLiked'] = isLiked;
          activity['likeCount'] = currentLikes;
        });
      }
    }
  }

  void _openComments(Map<String, dynamic> activity) {
    final id = activity['id'] as int?;
    if (id == null) return;
    final user = activity['user'] as Map<String, dynamic>?;
    final media = activity['media'] as Map<String, dynamic>?;
    final title = media != null
        ? (media['title']?['userPreferred'] as String?)
        : activity['status'] as String?;

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
        activityStatus: activity['status'] as String?,
        activityProgress: activity['progress'] != null ? '${activity['progress']}' : null,
        initialReplyCount: activity['replyCount'] as int? ?? 0,
        onReplyAdded: () {
          setState(() {
            activity['replyCount'] = (activity['replyCount'] as int? ?? 0) + 1;
          });
        },
      ),
    );
  }

  void _openLikes(Map<String, dynamic> activity) {
    final id = activity['id'] as int?;
    if (id == null) return;
    final user = activity['user'] as Map<String, dynamic>?;
    final media = activity['media'] as Map<String, dynamic>?;
    final rawLikes = activity['likes'] as List?;
    final initialLikes = rawLikes?.cast<Map<String, dynamic>>() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityLikesBottomSheet(
        activityId: id,
        media: media,
        activityStatus: activity['status'] as String?,
        activityProgress: activity['progress'] != null ? '${activity['progress']}' : null,
        activityUserName: user?['name'] as String?,
        initialLikes: initialLikes,
      ),
    );
  }

  void _openUserProfile(int? authorId) {
    if (authorId == null) return;
    // Don't push if already viewing this user's profile
    if (widget.userId == authorId) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: authorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final accentColor = auth is Authenticated
        ? AppColors.getProfileAccentColor(auth.user.profileColor)
        : AppColors.brandBlue;

    final content = _isLoading
        ? const ShimmerMediaGrid(count: 6)
        : RefreshIndicator(
            onRefresh: () => _load(page: 1),
            color: accentColor,
            backgroundColor: context.appSurface,
            child: _activities.isEmpty
                ? EmptyView(
                    title: widget.userId != null
                        ? 'No Activity Yet'
                        : (_isFollowing ? 'No Friends Activity Yet' : 'No Activity Found'),
                    subtitle: widget.userId != null
                        ? 'This user has not posted any status or list updates yet.'
                        : (_isFollowing
                            ? 'Follow people on AniList or switch to Global to see updates!'
                            : 'Check back later for recent updates.'),
                    icon: Icons.people_outline_rounded,
                    action: (widget.userId == null && _isFollowing)
                        ? TextButton(
                            onPressed: () {
                              setState(() => _isFollowing = false);
                              _load(page: 1);
                            },
                            child: const Text('Switch to Global Feed'),
                          )
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _activities.length + (_hasNextPage || _activities.isNotEmpty ? 1 : 0),
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == _activities.length) {
                        if (_hasNextPage) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _isLoadingMore
                                    ? null
                                    : () => _load(page: _currentPage + 1, reset: false),
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
                            ),
                          );
                        } else {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'No more activities ✨',
                                style: TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: context.appTextSecondary.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      final item = _activities[index];
                      final user = item['user'] as Map<String, dynamic>?;
                      final authorId = user?['id'] as int?;
                      final avatarUrl = user?['avatar']?['medium'] as String?;
                      final userName = user?['name'] as String? ?? 'Anonymous';
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
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author Header (Tappable to view Profile)
                            InkWell(
                              onTap: () => _openUserProfile(authorId),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    AppAvatar(imageUrl: avatarUrl, size: 36),
                                    const SizedBox(width: 10),
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
                                                    fontSize: 13.5,
                                                    color: context.appTextPrimary,
                                                  ),
                                                ),
                                                if (!isText) ...[
                                                  TextSpan(
                                                    text: ' ${item['status'] ?? 'updated'}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: context.appTextSecondary,
                                                    ),
                                                  ),
                                                  if (item['progress'] != null)
                                                    TextSpan(
                                                      text: ' ${item['progress']}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: accentColor,
                                                      ),
                                                    ),
                                                ],
                                              ],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            DateUtil.timeAgo(createdAt),
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: context.appTextMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Text Body or Media Card
                            if (isText) ...[
                              const SizedBox(height: 8),
                              Text(
                                item['text'] as String? ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: context.appTextPrimary,
                                ),
                              ),
                            ] else if (item['media'] != null) ...[
                              const SizedBox(height: 8),
                              InkWell(
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
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: context.appBackground,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                  ),
                                  child: Row(
                                    children: [
                                      AppNetworkImage(
                                        imageUrl: item['media']['coverImage']?['medium'],
                                        width: 32,
                                        height: 44,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item['media']['title']?['userPreferred'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Overpass',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: context.appTextPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Action Bar: LOVE ONLY (per user requirement)
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: isLiked
                                        ? AppColors.statusBehind.withValues(alpha: 0.12)
                                        : Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _toggleLike(index),
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
                                          child: Icon(
                                            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            size: 16,
                                            color: isLiked ? AppColors.statusBehind : context.appTextSecondary,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _openLikes(item),
                                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(2, 4, 8, 4),
                                          child: Text(
                                            '$likeCount',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isLiked ? AppColors.statusBehind : context.appTextSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _openComments(item),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 15,
                                            color: context.appTextSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            replyCount > 0 ? '$replyCount' : 'Reply',
                                            style: TextStyle(
                                              fontSize: 12,
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
                    },
                  ),
          );

    // If embedded inside ProfileScreen, do not wrap in a full Scaffold with nested AppBar
    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text(
          'Activity',
          style: TextStyle(
            fontFamily: 'Overpass',
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: context.appInputSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!_isFollowing) {
                          setState(() => _isFollowing = true);
                          _load(page: 1);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isFollowing ? context.appSurface : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: _isFollowing
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Friends Only',
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _isFollowing ? Colors.white : context.appTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (_isFollowing) {
                          setState(() => _isFollowing = false);
                          _load(page: 1);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isFollowing ? context.appSurface : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: !_isFollowing
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: !_isFollowing ? Colors.white : context.appTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: content,
    );
  }
}
