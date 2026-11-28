import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/settings/content_settings_provider.dart';
import '../../../../shared/feedback/shimmer_loading.dart';
import '../../../../shared/widgets/mankai_motifs.dart';
import '../../../activity/data/activity_repository.dart';
import '../../../activity/presentation/widgets/activity_actions.dart';
import '../../../activity/presentation/widgets/activity_card.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../profile/presentation/profile_screen.dart';

class HomeActivityFeed extends ConsumerStatefulWidget {
  const HomeActivityFeed({super.key});

  @override
  ConsumerState<HomeActivityFeed> createState() => HomeActivityFeedState();
}

class HomeActivityFeedState extends ConsumerState<HomeActivityFeed> {
  // Default to Following when authenticated; Guest Mode is Global-only.
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
    _isFollowing = ref.read(authControllerProvider) is Authenticated;
    loadActivities();
  }

  Future<void> loadActivities({int page = 1, bool reset = true}) async {
    final isAuthenticated = ref.read(authControllerProvider) is Authenticated;
    final effectiveFollowing = isAuthenticated && _isFollowing;
    if (!isAuthenticated && _isFollowing) {
      _isFollowing = false;
    }
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasNextPage = true;
      });
    }
    try {
      final repo = ref.read(activityRepositoryProvider);
      final data = await repo.fetchActivities(
        page: page,
        isFollowing: effectiveFollowing,
        includeAdult: ref.read(adultContentProvider),
      );
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final accentColor = context.isYuYuYu
        ? context.appAccent
        : (auth is Authenticated
            ? AppColors.getProfileAccentColor(auth.user.profileColor)
            : AppColors.brandBlue);
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

    ref.listen<bool>(adultContentProvider, (_, _) {
      loadActivities();
    });

    final isAuthenticated = auth is Authenticated;
    final effectiveFollowing = isAuthenticated && _isFollowing;
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      final wasAuth = prev is Authenticated;
      final isNowAuth = next is Authenticated;
      if (wasAuth != isNowAuth) {
        setState(() => _isFollowing = isNowAuth);
        loadActivities();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MankaiSectionHeader(
          title: 'ACTIVITY',
          dotColor: context.appAccent,
          trailing: !isAuthenticated
              ? Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: context.appInputSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.appBorder),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public_rounded,
                        size: 13,
                        color: context.appTextSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Global',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  height: 28,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: context.appInputSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Row(
                    children: [
                      _buildFeedSegment(
                        context,
                        label: 'Following',
                        selected: _isFollowing,
                        onTap: () {
                          if (!_isFollowing) {
                            setState(() => _isFollowing = true);
                            loadActivities();
                          }
                        },
                      ),
                      _buildFeedSegment(
                        context,
                        label: 'Global',
                        selected: !_isFollowing,
                        onTap: () {
                          if (_isFollowing) {
                            setState(() => _isFollowing = false);
                            loadActivities();
                          }
                        },
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 10),
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
                effectiveFollowing
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
              final userId = (item['user'] as Map<String, dynamic>?)?['id'] as int?;
              return ActivityCard(
                activity: item,
                accentColor: accentColor,
                currentViewerId: currentViewerId,
                compact: true,
                onUserTap: () {
                  if (userId != null) {
                    Navigator.of(context).push(
                      AppPageRoute(page: ProfileScreen(userId: userId)),
                    );
                  }
                },
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
          ),
      ],
    );
  }

  Widget _buildFeedSegment(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? context.appSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
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
          label,
          style: TextStyle(
            fontFamily: 'Overpass',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? context.appTextPrimary : context.appTextSecondary,
          ),
        ),
      ),
    );
  }
}
