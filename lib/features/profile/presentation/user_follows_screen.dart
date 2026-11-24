import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/image/app_avatar.dart';
import '../../../shared/image/app_network_image.dart';
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

  /// Cleans raw AniList markdown into a human-readable 1-2 line snippet for user cards
  static String? cleanBioForCard(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var text = raw;
    // 1. Strip images: img220(url), img(url), ![alt](url)
    text = text.replaceAll(RegExp(r'img(?:\d+%?|\d+)?\([^)]+\)', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), '');
    // 2. Strip video / audio / embeds
    text = text.replaceAll(RegExp(r'webm\([^)]+\)', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'youtube\([^)]+\)', caseSensitive: false), '');
    // 3. Convert markdown links [Label](url) -> Label
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m.group(1) ?? '');
    // 4. Strip html tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    // 5. Strip headers & centering: #, ~, >#
    text = text.replaceAll(RegExp(r'^[>#\s~]+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'[>#~]+'), '');
    // 6. Strip formatting symbols: **, __, *, _
    text = text.replaceAll(RegExp(r'[*_]{1,3}'), '');
    // 7. Normalize spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isNotEmpty ? text : null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final accentColor = auth is Authenticated
        ? AppColors.getProfileAccentColor(auth.user.profileColor)
        : AppColors.brandBlue;
    final loggedInUserId = auth is Authenticated ? auth.user.id : null;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          widget.userName,
          style: TextStyle(
            fontFamily: 'Overpass',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: context.appTextPrimary,
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
                color: context.appInputSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.appBorder),
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
                            color: _selectedTab == 0 ? Colors.white : context.appTextSecondary,
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
                            color: _selectedTab == 1 ? Colors.white : context.appTextSecondary,
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
                    backgroundColor: context.appSurface,
                    child: _users.isEmpty
                        ? EmptyView(
                            title: _selectedTab == 0 ? 'Not Following Anyone' : 'No Followers Yet',
                            subtitle: _selectedTab == 0
                                ? '${widget.userName} is not following anyone yet.'
                                : '${widget.userName} does not have any followers yet.',
                            icon: Icons.people_outline_rounded,
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollUpdateNotification) {
                                if (notification.metrics.extentAfter < 350 &&
                                    !_isLoadingMore &&
                                    _hasNextPage) {
                                  _loadList(page: _currentPage + 1, reset: false);
                                }
                              }
                              return false;
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _users.length + (_hasNextPage ? 1 : 0),
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index == _users.length) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final user = _users[index];
                                final id = user['id'] as int;
                                final name = user['name'] as String? ?? 'User';
                                final avatar = user['avatar']?['large'] as String? ?? user['avatar']?['medium'] as String?;
                                final banner = user['bannerImage'] as String?;
                                final isFollowing = user['isFollowing'] as bool? ?? false;
                                final isFollower = user['isFollower'] as bool? ?? false;
                                final isMe = loggedInUserId != null && loggedInUserId == id;
                                final aboutText = cleanBioForCard(user['about'] as String?);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: context.appSurface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: context.appBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: context.isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ProfileScreen(userId: id),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Mini Banner Header
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            SizedBox(
                                              height: 74,
                                              width: double.infinity,
                                              child: banner != null
                                                  ? AppNetworkImage(imageUrl: banner, borderRadius: BorderRadius.zero)
                                                  : Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                          colors: [
                                                            accentColor.withValues(alpha: 0.35),
                                                            const Color(0xFF0F1E2E),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.transparent,
                                                      Colors.black.withValues(alpha: 0.65),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Pop-out Circular Avatar
                                            Positioned(
                                              left: 14,
                                              bottom: -22,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: context.appSurface, width: 3.5),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.5),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: AppAvatar(imageUrl: avatar, size: 50),
                                              ),
                                            ),
                                            // Follow / Unfollow Button
                                            if (auth is Authenticated && !isMe)
                                              Positioned(
                                                right: 12,
                                                bottom: 10,
                                                child: GestureDetector(
                                                  onTap: () => _toggleFollow(index),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: isFollowing
                                                          ? (context.isDark
                                                              ? Colors.black.withValues(alpha: 0.45)
                                                              : Colors.white.withValues(alpha: 0.95))
                                                          : accentColor,
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: isFollowing ? accentColor : Colors.transparent,
                                                        width: 1.2,
                                                      ),
                                                      boxShadow: !isFollowing
                                                          ? [
                                                              BoxShadow(
                                                                color: accentColor.withValues(alpha: 0.4),
                                                                blurRadius: 6,
                                                                offset: const Offset(0, 1),
                                                              ),
                                                            ]
                                                          : null,
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          isFollowing
                                                              ? Icons.check_rounded
                                                              : (isFollower ? Icons.sync_alt_rounded : Icons.add_rounded),
                                                          size: 12,
                                                          color: isFollowing ? accentColor : Colors.white,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          isFollowing
                                                              ? 'Following'
                                                              : (isFollower ? 'Follow Back' : 'Follow'),
                                                          style: TextStyle(
                                                            fontFamily: 'Overpass',
                                                            fontWeight: FontWeight.w800,
                                                            fontSize: 11,
                                                            color: isFollowing ? accentColor : Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),

                                        // Body Info
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily: 'Overpass',
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 14.5,
                                                        color: context.appTextPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Mutual / Follows you Badge
                                                  if (isFollowing && isFollower)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.scoreHigh.withValues(alpha: 0.18),
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(color: AppColors.scoreHigh.withValues(alpha: 0.5)),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.sync_alt_rounded, size: 10, color: AppColors.scoreHigh),
                                                          SizedBox(width: 3),
                                                          Text(
                                                            'Mutual',
                                                            style: TextStyle(
                                                              fontFamily: 'Overpass',
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w800,
                                                              color: AppColors.scoreHigh,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  else if (isFollower && !isFollowing)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.brandBlue.withValues(alpha: 0.18),
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.5)),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.south_west_rounded, size: 10, color: AppColors.brandBlue),
                                                          SizedBox(width: 3),
                                                          Text(
                                                            'Follows you',
                                                            style: TextStyle(
                                                              fontFamily: 'Overpass',
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w800,
                                                              color: AppColors.brandBlue,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              if (aboutText != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  aboutText,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: 'Overpass',
                                                    fontSize: 12,
                                                    height: 1.35,
                                                    color: context.appTextSecondary,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
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
