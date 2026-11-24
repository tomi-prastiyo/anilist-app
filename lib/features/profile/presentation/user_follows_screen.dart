import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/image/app_avatar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/profile_repository.dart';
import 'profile_screen.dart';

class UserFollowsScreen extends ConsumerStatefulWidget {
  final int userId;
  final String userName;
  final int initialTab; // 0: Following, 1: Followers

  const UserFollowsScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.initialTab = 0,
  });

  @override
  ConsumerState<UserFollowsScreen> createState() => _UserFollowsScreenState();
}

class _UserFollowsScreenState extends ConsumerState<UserFollowsScreen> {
  late int _selectedTab; // 0: Following, 1: Followers
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNextPage = true;
  List<Map<String, dynamic>> _users = [];
  int _followingTotal = 0;
  int _followersTotal = 0;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final repo = ref.read(profileRepositoryProvider);
    // Fetch counts
    final counts = await repo.fetchFollowCounts(userId: widget.userId);
    if (mounted) {
      setState(() {
        _followingTotal = counts['following'] ?? 0;
        _followersTotal = counts['followers'] ?? 0;
      });
    }
    await _loadList(page: 1, reset: true);
  }

  Future<void> _loadList({required int page, bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final repo = ref.read(profileRepositoryProvider);
      final Map<String, dynamic> pageData;
      if (_selectedTab == 0) {
        pageData = await repo.fetchUserFollowing(userId: widget.userId, page: page);
      } else {
        pageData = await repo.fetchUserFollowers(userId: widget.userId, page: page);
      }

      final pageInfo = pageData['pageInfo'] as Map<String, dynamic>?;
      final rawList = (_selectedTab == 0 ? pageData['following'] : pageData['followers']) as List?;
      final list = rawList?.cast<Map<String, dynamic>>() ?? [];

      if (mounted) {
        setState(() {
          if (reset) {
            _users = list;
          } else {
            _users.addAll(list);
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

  Future<void> _toggleFollow(int index) async {
    HapticFeedback.lightImpact();
    final user = _users[index];
    final isFollowing = user['isFollowing'] as bool? ?? false;
    final targetId = user['id'] as int;

    setState(() {
      user['isFollowing'] = !isFollowing;
    });

    try {
      final repo = ref.read(profileRepositoryProvider);
      final newStatus = await repo.toggleFollow(targetId);
      if (mounted) {
        setState(() {
          user['isFollowing'] = newStatus;
        });
      }
    } catch (_) {
      // Revert if error
      if (mounted) {
        setState(() {
          user['isFollowing'] = isFollowing;
        });
      }
    }
  }

  void _switchTab(int tabIndex) {
    if (_selectedTab == tabIndex) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedTab = tabIndex;
    });
    _loadList(page: 1, reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final accentColor = auth is Authenticated
        ? AppColors.getProfileAccentColor(auth.user.profileColor)
        : AppColors.brandBlue;
    final loggedInUserId = auth is Authenticated ? auth.user.id : null;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          widget.userName,
          style: const TextStyle(
            fontFamily: 'Overpass',
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Segmented Pill Tab Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: 8),
            child: Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceInput,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchTab(0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? accentColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _selectedTab == 0
                              ? [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Following ($_followingTotal)',
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _selectedTab == 0 ? Colors.white : AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchTab(1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? accentColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _selectedTab == 1
                              ? [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Followers ($_followersTotal)',
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _selectedTab == 1 ? Colors.white : AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // User List
          Expanded(
            child: _isLoading
                ? const ShimmerMediaGrid(count: 8)
                : RefreshIndicator(
                    onRefresh: () => _loadList(page: 1, reset: true),
                    color: accentColor,
                    backgroundColor: AppColors.darkSurface,
                    child: _users.isEmpty
                        ? EmptyView(
                            title: _selectedTab == 0 ? 'Not Following Anyone' : 'No Followers Yet',
                            subtitle: _selectedTab == 0
                                ? '${widget.userName} is not following anyone yet.'
                                : '${widget.userName} does not have any followers yet.',
                            icon: Icons.people_outline_rounded,
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (!_isLoadingMore &&
                                  _hasNextPage &&
                                  scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8) {
                                _loadList(page: _currentPage + 1, reset: false);
                              }
                              return false;
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _users.length + (_hasNextPage ? 1 : 0),
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                if (index == _users.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final user = _users[index];
                                final id = user['id'] as int;
                                final name = user['name'] as String? ?? 'User';
                                final avatar = user['avatar']?['medium'] as String?;
                                final isFollowing = user['isFollowing'] as bool? ?? false;
                                final isMe = loggedInUserId != null && loggedInUserId == id;

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ProfileScreen(userId: id),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Row(
                                      children: [
                                        AppAvatar(imageUrl: avatar, size: 44),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontFamily: 'Overpass',
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                user['about'] != null && (user['about'] as String).isNotEmpty
                                                    ? (user['about'] as String).replaceAll(RegExp(r'\n+'), ' ').trim()
                                                    : 'AniList User',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppColors.darkTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (auth is Authenticated && !isMe) ...[
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => _toggleFollow(index),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isFollowing ? Colors.transparent : accentColor,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: isFollowing
                                                      ? AppColors.darkTextSecondary.withValues(alpha: 0.4)
                                                      : accentColor,
                                                ),
                                              ),
                                              child: Text(
                                                isFollowing ? 'Following' : 'Follow',
                                                style: TextStyle(
                                                  fontFamily: 'Overpass',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11.5,
                                                  color: isFollowing ? AppColors.darkTextSecondary : Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
