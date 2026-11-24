import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/cards/media_card.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/image/app_avatar.dart';
import '../../../shared/image/app_network_image.dart';
import '../../activity/presentation/activity_screen.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../character_staff/presentation/character_detail_screen.dart';
import '../../character_staff/presentation/staff_detail_screen.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/profile_repository.dart';
import 'user_follows_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final int? userId;
  final String? userName;

  const ProfileScreen({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  int _followingCount = 0;
  int _followersCount = 0;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.userName != widget.userName) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isOwnProfile(dynamic authUser) {
    if (widget.userId == null && widget.userName == null) return true;
    if (authUser != null) {
      if (widget.userId != null && widget.userId == authUser.id) return true;
      if (widget.userName != null && widget.userName == authUser.name) return true;
    }
    return false;
  }

  Future<void> _loadProfile() async {
    final auth = ref.read(authControllerProvider);
    final authUser = auth is Authenticated ? auth.user : null;
    final isOwn = _isOwnProfile(authUser);

    // If viewing own profile and not signed in, show unauthenticated empty state
    if (isOwn && authUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(profileRepositoryProvider);
      final targetUserId = widget.userId ?? (isOwn ? authUser?.id : null);
      final targetUserName = widget.userName ?? (isOwn ? authUser?.name : null);

      final profile = await repo.fetchUserProfile(
        userId: targetUserId,
        userName: targetUserName,
      );

      final profileId = profile['id'] as int? ?? targetUserId;
      Map<String, int> counts = {'following': 0, 'followers': 0};
      if (profileId != null && profileId > 0) {
        counts = await repo.fetchFollowCounts(userId: profileId);
      }

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isFollowing = profile['isFollowing'] as bool? ?? false;
          _followingCount = counts['following'] ?? 0;
          _followersCount = counts['followers'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_userProfile == null) return;
    HapticFeedback.lightImpact();
    final previousStatus = _isFollowing;
    final previousFollowers = _followersCount;

    setState(() {
      _isFollowing = !previousStatus;
      _followersCount = _isFollowing ? previousFollowers + 1 : (previousFollowers > 0 ? previousFollowers - 1 : 0);
    });

    try {
      final repo = ref.read(profileRepositoryProvider);
      final targetId = _userProfile!['id'] as int;
      final newStatus = await repo.toggleFollow(targetId);
      if (mounted) {
        setState(() => _isFollowing = newStatus);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFollowing = previousStatus;
          _followersCount = previousFollowers;
        });
      }
    }
  }

  void _openFollowsScreen(int tab) {
    final profileId = _userProfile?['id'] as int? ?? widget.userId;
    final profileName = _userProfile?['name'] as String? ?? widget.userName ?? 'User';
    if (profileId == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserFollowsScreen(
          userId: profileId,
          userName: profileName,
          initialTab: tab,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isAuthenticated = auth is Authenticated;
    final authUser = isAuthenticated ? auth.user : null;
    final isOwn = _isOwnProfile(authUser);

    // Unauthenticated viewing own profile
    if (isOwn && !isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(title: const Text('Profile')),
        body: EmptyView(
          title: 'Sign in to see your profile',
          subtitle: 'View your anime & manga stats, favorites, friends, and personal activity.',
          icon: Icons.person_outline_rounded,
          action: ElevatedButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign In with AniList'),
          ),
        ),
      );
    }

    if (_errorMessage != null && _userProfile == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(title: const Text('Profile')),
        body: ErrorView(
          message: _errorMessage!,
          onRetry: _loadProfile,
        ),
      );
    }

    final userName = _userProfile?['name'] as String? ?? (isOwn ? authUser?.name : (widget.userName ?? 'User'));
    final userAvatar = _userProfile?['avatar']?['large'] as String? ?? (isOwn ? authUser?.avatarUrl : null);
    final userBanner = _userProfile?['bannerImage'] as String? ?? (isOwn ? authUser?.bannerUrl : null);
    final accentColor = isOwn
        ? AppColors.getProfileAccentColor(authUser?.profileColor)
        : AppColors.brandBlue;
    final profileId = _userProfile?['id'] as int? ?? (isOwn ? authUser?.id : widget.userId);

    // Stats
    final stats = _userProfile?['statistics']?['anime'] as Map<String, dynamic>?;
    final mangaStats = _userProfile?['statistics']?['manga'] as Map<String, dynamic>?;
    final count = stats?['count'] as int? ?? 0;
    final minutes = stats?['minutesWatched'] as int? ?? 0;
    final days = (minutes / (60 * 24)).toStringAsFixed(1);
    final meanScore = (stats?['meanScore'] as num?)?.toDouble() ?? 0.0;
    final stdDev = (stats?['standardDeviation'] as num?)?.toDouble() ?? 0.0;
    final episodes = stats?['episodesWatched'] as int? ?? 0;
    final mangaChapters = mangaStats?['chaptersRead'] as int? ?? 0;
    final mangaCount = mangaStats?['count'] as int? ?? 0;
    final scoreList = (stats?['scores'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final formatList = (stats?['formats'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final genreList = (stats?['genres'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Favourites
    final favs = _userProfile?['favourites'] as Map<String, dynamic>?;
    final favAnime = (favs?['anime']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final favManga = (favs?['manga']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final favCharacters = (favs?['characters']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final favStaff = (favs?['staff']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 225,
            pinned: true,
            backgroundColor: AppColors.darkBackground,
            leading: !isOwn
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
            actions: isOwn
                ? [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.darkBackground.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 18),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.darkBackground.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(Icons.settings_outlined, color: Colors.white, size: 18),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Banner Image
                  if (userBanner != null)
                    AppNetworkImage(imageUrl: userBanner, borderRadius: BorderRadius.zero)
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0E2238), Color(0xFF162A44)],
                        ),
                      ),
                    ),
                  // Dark Multi-stop Gradient Scrim
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.darkBackground.withValues(alpha: 0.2),
                          AppColors.darkBackground.withValues(alpha: 0.7),
                          AppColors.darkBackground,
                        ],
                        stops: const [0.0, 0.4, 0.75, 1.0],
                      ),
                    ),
                  ),

                  // User Info Area (Overlapping Banner)
                  Positioned(
                    bottom: 10,
                    left: 16,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Portrait Rectangular Avatar (AniList Authentic: 76x96, 10px radius)
                        Container(
                          width: 76,
                          height: 96,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.darkSurface, width: 3),
                            color: AppColors.darkSurface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: userAvatar != null
                                ? AppNetworkImage(imageUrl: userAvatar, fit: BoxFit.cover)
                                : const Icon(Icons.person, size: 36, color: AppColors.darkTextSecondary),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Username, Badges, Following/Followers, & Follow Button
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      userName ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Overpass',
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Follow Button (if viewing another user's profile)
                                  if (!isOwn && isAuthenticated) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _toggleFollow,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _isFollowing ? AppColors.darkSurface : accentColor,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: _isFollowing ? accentColor : Colors.transparent,
                                          ),
                                          boxShadow: !_isFollowing
                                              ? [
                                                  BoxShadow(
                                                    color: accentColor.withValues(alpha: 0.35),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _isFollowing ? Icons.check_rounded : Icons.add_rounded,
                                              size: 13,
                                              color: _isFollowing ? accentColor : Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _isFollowing ? 'Following' : 'Follow',
                                              style: TextStyle(
                                                fontFamily: 'Overpass',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                color: _isFollowing ? accentColor : Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),

                              // AniList Member Badge
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkSurface.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: accentColor,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Text(
                                          'AniList Member',
                                          style: TextStyle(
                                            fontFamily: 'Overpass',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.darkTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Interactive Following & Followers Counters (Optimized Touch Targets)
                              Row(
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _openFollowsScreen(0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$_followingCount',
                                            style: const TextStyle(
                                              fontFamily: 'Overpass',
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Following',
                                            style: TextStyle(
                                              fontFamily: 'Overpass',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.darkTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _openFollowsScreen(1),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$_followersCount',
                                            style: const TextStyle(
                                              fontFamily: 'Overpass',
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Followers',
                                            style: TextStyle(
                                              fontFamily: 'Overpass',
                                              fontSize: 11.5,
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pinned Modern Pill Tabs Bar (Consistently styled with Home, MediaList & Search)
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfilePillTabsDelegate(
              tabController: _tabController,
              accentColor: accentColor,
              isOwnProfile: isOwn,
            ),
          ),
        ],
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: accentColor))
            : RefreshIndicator(
                onRefresh: _loadProfile,
                color: accentColor,
                backgroundColor: AppColors.darkSurface,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Stats & Visual Charts
                    _buildStatsTab(
                      count: count,
                      days: days,
                      meanScore: meanScore,
                      stdDev: stdDev,
                      episodes: episodes,
                      mangaChapters: mangaChapters,
                      mangaCount: mangaCount,
                      scoreList: scoreList,
                      formatList: formatList,
                      genreList: genreList,
                      accentColor: accentColor,
                    ),

                    // Tab 2: Favorites
                    _buildFavoritesTab(
                      favAnime: favAnime,
                      favManga: favManga,
                      favCharacters: favCharacters,
                      favStaff: favStaff,
                    ),

                    // Tab 3: Personal Activity Feed (Only this user's activity)
                    ActivityScreen(
                      userId: profileId,
                      isEmbedded: true,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsTab({
    required int count,
    required String days,
    required double meanScore,
    required double stdDev,
    required int episodes,
    required int mangaChapters,
    required int mangaCount,
    required List<Map<String, dynamic>> scoreList,
    required List<Map<String, dynamic>> formatList,
    required List<Map<String, dynamic>> genreList,
    required Color accentColor,
  }) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.p16),
      children: [
        // 1. Sleek 2x3 Quick Stat Neo-Cards
        Row(
          children: [
            _statCard('Total Anime', '$count', Icons.tv_rounded, accentColor, const Color(0xFF3DB4F2)),
            const SizedBox(width: 8),
            _statCard('Days Watched', '${days}d', Icons.access_time_rounded, accentColor, const Color(0xFF00B4D8)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard('Mean Score', meanScore > 0 ? '${meanScore.toStringAsFixed(1)}%' : '-', Icons.star_rounded, accentColor, const Color(0xFFFFB703)),
            const SizedBox(width: 8),
            _statCard('Std Dev', stdDev > 0 ? stdDev.toStringAsFixed(1) : '-', Icons.query_stats_rounded, accentColor, const Color(0xFFE056FD)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard('Episodes', '$episodes', Icons.play_circle_outline_rounded, accentColor, const Color(0xFF06D6A0)),
            const SizedBox(width: 8),
            _statCard('Manga Chapters', '$mangaChapters', Icons.menu_book_rounded, accentColor, const Color(0xFF9D4EDD)),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Score Distribution Histogram (Scores 10 to 100)
        if (scoreList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.bar_chart_rounded, size: 16, color: accentColor),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Score Distribution',
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
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '10 – 100',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 140,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: scoreList.map((e) => (e['count'] as num).toDouble()).fold(0.0, (a, b) => a > b ? a : b) * 1.25 + 2,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < scoreList.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '${scoreList[idx]['score']}',
                                    style: const TextStyle(
                                      fontFamily: 'Overpass',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkTextSecondary,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: scoreList.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final countVal = (entry.value['count'] as num).toDouble();
                        return BarChartGroupData(
                          x: idx,
                          showingTooltipIndicators: countVal > 0 ? [0] : [],
                          barRods: [
                            BarChartRodData(
                              toY: countVal,
                              color: accentColor,
                              width: 14,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 3. Format Breakdown (Donut Chart)
        if (formatList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.pie_chart_outline_rounded, size: 16, color: accentColor),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Format Breakdown',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: formatList.take(5).map((f) {
                        final format = f['format'] as String? ?? '';
                        final cnt = (f['count'] as num?)?.toDouble() ?? 0.0;
                        Color color = accentColor;
                        if (format == 'MOVIE') color = AppColors.statusCompleted;
                        if (format == 'OVA') color = AppColors.statusPaused;
                        if (format == 'SPECIAL') color = AppColors.statusPlanning;
                        if (format == 'MANGA') color = AppColors.statusRepeating;

                        return PieChartSectionData(
                          value: cnt,
                          title: format,
                          radius: 35,
                          titleStyle: const TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          color: color,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 4. Top Genres Breakdown Progress Bars
        if (genreList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.category_rounded, size: 16, color: accentColor),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Top Genres',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...genreList.take(6).map((g) {
                  final genre = g['genre'] as String? ?? '';
                  final cnt = g['count'] as int? ?? 0;
                  final maxCnt = (genreList.first['count'] as num?)?.toDouble() ?? 1.0;
                  final progress = (cnt / maxCnt).clamp(0.0, 1.0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              genre,
                              style: const TextStyle(
                                fontFamily: 'Overpass',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkTextPrimary,
                              ),
                            ),
                            Text(
                              '$cnt entries',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.darkTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.darkBorder,
                            color: accentColor,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFavoritesTab({
    required List<Map<String, dynamic>> favAnime,
    required List<Map<String, dynamic>> favManga,
    required List<Map<String, dynamic>> favCharacters,
    required List<Map<String, dynamic>> favStaff,
  }) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.p16),
      children: [
        if (favAnime.isNotEmpty)
          _favMediaSection('Favorite Anime', favAnime),
        if (favManga.isNotEmpty)
          _favMediaSection('Favorite Manga', favManga),
        if (favCharacters.isNotEmpty)
          _favPersonSection('Favorite Characters', favCharacters, isCharacter: true),
        if (favStaff.isNotEmpty)
          _favPersonSection('Favorite Staff', favStaff, isCharacter: false),
        if (favAnime.isEmpty && favManga.isEmpty && favCharacters.isEmpty && favStaff.isEmpty)
          const EmptyView(
            title: 'No Favorites Yet',
            subtitle: 'Heart anime, manga, and characters to showcase them here.',
            icon: Icons.favorite_border_rounded,
          ),
      ],
    );
  }

  Widget _favMediaSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Overpass',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              '${items.length} titles',
              style: const TextStyle(
                fontFamily: 'Overpass',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final media = items[index];
              return SizedBox(
                width: 110,
                child: MediaCard(
                  media: media,
                  mode: MediaCardMode.grid,
                  onTap: () {
                    final id = media['id'] as int?;
                    if (id != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => MediaDetailScreen(mediaId: id)),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _favPersonSection(String title, List<Map<String, dynamic>> items, {required bool isCharacter}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Overpass',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              '${items.length} items',
              style: const TextStyle(
                fontFamily: 'Overpass',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final name = item['name']?['userPreferred'] ?? '';
              final image = item['image']?['medium'] as String?;

              return InkWell(
                onTap: () {
                  final id = item['id'] as int?;
                  if (id != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => isCharacter
                            ? CharacterDetailScreen(characterId: id)
                            : StaffDetailScreen(staffId: id),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    AppAvatar(imageUrl: image, size: 52),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 68,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accentColor, [Color? iconColor]) {
    final effectiveColor = iconColor ?? accentColor;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.p12),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: effectiveColor),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Overpass',
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
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
    );
  }
}

class _ProfilePillTabsDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Color accentColor;
  final bool isOwnProfile;

  _ProfilePillTabsDelegate({
    required this.tabController,
    required this.accentColor,
    required this.isOwnProfile,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.darkBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AnimatedBuilder(
        animation: tabController,
        builder: (context, _) {
          return Row(
            children: [
              _buildPill(0, 'Stats', Icons.bar_chart_rounded),
              const SizedBox(width: 8),
              _buildPill(1, 'Favorites', Icons.favorite_rounded),
              const SizedBox(width: 8),
              _buildPill(2, isOwnProfile ? 'My Activity' : 'Activity', Icons.history_rounded),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPill(int index, String title, IconData icon) {
    final isSelected = tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? accentColor : AppColors.darkSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.06),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.darkTextSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_ProfilePillTabsDelegate oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.isOwnProfile != isOwnProfile ||
        oldDelegate.tabController != tabController;
  }
}
