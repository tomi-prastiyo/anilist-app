import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/activity_repository.dart';
import 'widgets/activity_actions.dart';
import 'widgets/activity_card.dart';

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
  final Set<int> _togglingLikeIds = {};

  @override
  void initState() {
    super.initState();
    _isFollowing = ref.read(authControllerProvider) is Authenticated;
    _load(page: 1);
  }

  @override
  void didUpdateWidget(covariant ActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _load(page: 1);
    }
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
      final isAuthenticated = ref.read(authControllerProvider) is Authenticated;
      final effectiveFollowing = isAuthenticated && _isFollowing;
      final pageData = await repo.fetchActivities(
        page: page,
        userId: widget.userId,
        isFollowing: widget.userId == null ? effectiveFollowing : null,
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

  Future<void> _deleteActivity(int index) async {
    final activity = _activities[index];
    final id = activity['id'] as int?;
    if (id == null) return;

    await ActivityActions.confirmAndDelete(
      context: context,
      ref: ref,
      activityId: id,
      isMounted: () => mounted,
      onOptimisticRemove: () => setState(() => _activities.removeAt(index)),
      onRevert: () => setState(
        () => _activities.insert(index.clamp(0, _activities.length), activity),
      ),
    );
  }

  Future<void> _toggleLike(int index) async {
    final activity = _activities[index];
    await ActivityActions.toggleLike(
      context: context,
      ref: ref,
      activity: activity,
      inFlightIds: _togglingLikeIds,
      isMounted: () => mounted,
      applyUpdate: (isLiked, likeCount) {
        setState(() {
          activity['isLiked'] = isLiked;
          activity['likeCount'] = likeCount;
        });
      },
    );
  }

  void _openUserProfile(int? authorId) {
    if (authorId == null) return;
    if (widget.userId == authorId) return;

    Navigator.of(context).push(
      AppPageRoute(page: ProfileScreen(userId: authorId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final accentColor = auth is Authenticated
        ? AppColors.getProfileAccentColor(auth.user.profileColor)
        : AppColors.brandBlue;
    final currentViewerId = auth is Authenticated ? auth.user.id : null;

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

    final isAuthenticated = auth is Authenticated;
    final effectiveFollowing = isAuthenticated && _isFollowing;

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
                        : (effectiveFollowing ? 'No Friends Activity Yet' : 'No Activity Found'),
                    subtitle: widget.userId != null
                        ? 'This user has not posted any status or list updates yet.'
                        : (effectiveFollowing
                            ? 'Follow people on AniList or switch to Global to see updates!'
                            : 'Check back later for recent updates.'),
                    icon: Icons.people_outline_rounded,
                    action: (widget.userId == null && effectiveFollowing)
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
                        }
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

                      final item = _activities[index];
                      final authorId = (item['user'] as Map<String, dynamic>?)?['id'] as int?;

                      return ActivityCard(
                        activity: item,
                        accentColor: accentColor,
                        currentViewerId: currentViewerId,
                        compact: false,
                        onUserTap: () => _openUserProfile(authorId),
                        onLikeTap: () => _toggleLike(index),
                        onLikesCountTap: () => ActivityActions.openLikes(
                          context: context,
                          activity: item,
                        ),
                        onCommentsTap: () => ActivityActions.openComments(
                          context: context,
                          activity: item,
                          onReplyAdded: () => setState(() {
                            item['replyCount'] = (item['replyCount'] as int? ?? 0) + 1;
                          }),
                        ),
                        onDeleteTap: () => _deleteActivity(index),
                      ).animateEntrance(index: index);
                    },
                  ),
          );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          isAuthenticated ? 'Activity' : 'Global Activity',
          style: const TextStyle(
            fontFamily: 'Overpass',
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        bottom: !isAuthenticated
            ? null
            : PreferredSize(
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
                        _buildAppBarSegment(
                          context,
                          label: 'Friends Only',
                          selected: _isFollowing,
                          onTap: () {
                            if (!_isFollowing) {
                              setState(() => _isFollowing = true);
                              _load(page: 1);
                            }
                          },
                        ),
                        _buildAppBarSegment(
                          context,
                          label: 'Global',
                          selected: !_isFollowing,
                          onTap: () {
                            if (_isFollowing) {
                              setState(() => _isFollowing = false);
                              _load(page: 1);
                            }
                          },
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

  Widget _buildAppBarSegment(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? context.appSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: selected
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
            label,
            style: TextStyle(
              fontFamily: 'Overpass',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : context.appTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
