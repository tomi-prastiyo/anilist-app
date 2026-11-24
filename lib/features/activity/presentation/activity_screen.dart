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
  int _currentPage = 1;
  bool _hasNextPage = true;
  final TextEditingController _postController = TextEditingController();

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
    _postController.dispose();
    super.dispose();
  }

  Future<void> _load({required int page, bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
      });
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
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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

  void _showNewPostDialog() {
    final auth = ref.read(authControllerProvider);
    final accentColor = auth is Authenticated
        ? AppColors.getProfileAccentColor(auth.user.profileColor)
        : AppColors.brandBlue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'New Status Post',
          style: TextStyle(
            fontFamily: 'Overpass',
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: TextField(
          controller: _postController,
          maxLines: 4,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Share your thoughts with AniList...',
            hintStyle: const TextStyle(color: AppColors.darkTextMuted),
            fillColor: AppColors.darkSurfaceInput,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = _postController.text.trim();
              if (text.isEmpty) return;
              Navigator.of(context).pop();
              try {
                final repo = ref.read(activityRepositoryProvider);
                await repo.saveTextActivity(text);
                _postController.clear();
                _load(page: 1);
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
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
    final isOwnProfile = widget.userId == null || (auth is Authenticated && widget.userId == auth.user.id);

    final content = _isLoading
        ? const ShimmerMediaGrid(count: 6)
        : RefreshIndicator(
            onRefresh: () => _load(page: 1),
            color: accentColor,
            backgroundColor: AppColors.darkSurface,
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
                    itemCount: _activities.length + (_hasNextPage ? 1 : 0),
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == _activities.length) {
                        _load(page: _currentPage + 1, reset: false);
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
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
                          color: AppColors.darkSurface,
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
                                                  style: const TextStyle(
                                                    fontFamily: 'Overpass',
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 13.5,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                if (!isText) ...[
                                                  TextSpan(
                                                    text: ' ${item['status'] ?? 'updated'}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.darkTextSecondary,
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
                                            style: const TextStyle(
                                              fontSize: 10.5,
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

                            // Text Body or Media Card
                            if (isText) ...[
                              const SizedBox(height: 8),
                              Text(
                                item['text'] as String? ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppColors.darkTextPrimary,
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
                                    color: AppColors.darkBackground,
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
                                          style: const TextStyle(
                                            fontFamily: 'Overpass',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: Colors.white,
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
                                InkWell(
                                  onTap: () => _toggleLike(index),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isLiked
                                          ? AppColors.statusBehind.withValues(alpha: 0.12)
                                          : Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          size: 16,
                                          color: isLiked ? AppColors.statusBehind : AppColors.darkTextSecondary,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '$likeCount',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isLiked ? AppColors.statusBehind : AppColors.darkTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (replyCount > 0) ...[
                                  const SizedBox(width: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 14,
                                        color: AppColors.darkTextMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$replyCount',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.darkTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
      return Stack(
        children: [
          content,
          if (isOwnProfile)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'profile_activity_fab',
                onPressed: _showNewPostDialog,
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                mini: true,
                child: const Icon(Icons.edit_rounded, size: 20),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
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
                color: AppColors.darkSurfaceInput,
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
                          color: _isFollowing ? AppColors.darkSurface : Colors.transparent,
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
                            color: _isFollowing ? Colors.white : AppColors.darkTextSecondary,
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
                          color: !_isFollowing ? AppColors.darkSurface : Colors.transparent,
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
                            color: !_isFollowing ? Colors.white : AppColors.darkTextSecondary,
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'global_activity_fab',
        onPressed: _showNewPostDialog,
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit_rounded),
      ),
      body: content,
    );
  }
}
