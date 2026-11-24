import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/anilist_bio_widget.dart';
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
  bool _isFollower = false;

  String _statsMode = 'ANIME'; // 'ANIME', 'MANGA'
  String _favFilter = 'ALL'; // 'ALL', 'ANIME', 'MANGA', 'CHARACTERS', 'STAFF'

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
          _isFollower = profile['isFollower'] as bool? ?? false;
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
        backgroundColor: context.appBackground,
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
        backgroundColor: context.appBackground,
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
    final animeStatuses = (stats?['statuses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final scoreList = (stats?['scores'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final formatList = (stats?['formats'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final genreList = (stats?['genres'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final mangaCount = mangaStats?['count'] as int? ?? 0;
    final mangaChapters = mangaStats?['chaptersRead'] as int? ?? 0;
    final mangaVolumes = mangaStats?['volumesRead'] as int? ?? 0;
    final mangaMeanScore = (mangaStats?['meanScore'] as num?)?.toDouble() ?? 0.0;
    final mangaStatuses = (mangaStats?['statuses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final mangaScores = (mangaStats?['scores'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final mangaGenres = (mangaStats?['genres'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final about = _userProfile?['about'] as String?;

    // Favourites
    final favs = _userProfile?['favourites'] as Map<String, dynamic>?;
    final favAnime = (favs?['anime']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final favManga = (favs?['manga']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final favCharacters = (favs?['characters']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final favStaff = (favs?['staff']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: context.appBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 225,
            pinned: true,
            backgroundColor: context.appBackground,
            leading: !isOwn
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
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
                          color: Colors.black.withValues(alpha: 0.5),
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
                          color: Colors.black.withValues(alpha: 0.5),
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
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.85),
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
                        // Circular Pop-out Avatar
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: context.appSurface, width: 3.5),
                            color: context.appSurface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: userAvatar != null
                                ? AppNetworkImage(imageUrl: userAvatar, fit: BoxFit.cover)
                                : const Icon(Icons.person, size: 40, color: AppColors.darkTextSecondary),
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
                                        fontSize: 20,
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
                                          color: _isFollowing ? context.appSurface : accentColor,
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
                                              _isFollowing
                                                  ? Icons.check_rounded
                                                  : (_isFollower ? Icons.sync_alt_rounded : Icons.person_add_rounded),
                                              size: 13,
                                              color: _isFollowing ? accentColor : Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _isFollowing
                                                  ? 'Following'
                                                  : (_isFollower ? 'Follow Back' : 'Follow'),
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
                              const SizedBox(height: 5),

                              // Relation Badges (Mutual / Follows you / Following) & AniList Member Badge
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (!isOwn && isAuthenticated) ...[
                                    if (_isFollowing && _isFollower)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.scoreHigh.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.scoreHigh.withValues(alpha: 0.6)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.sync_alt_rounded, size: 11, color: AppColors.scoreHigh),
                                            SizedBox(width: 4),
                                            Text(
                                              'Mutual',
                                              style: TextStyle(
                                                fontFamily: 'Overpass',
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.scoreHigh,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (_isFollower && !_isFollowing)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.brandBlue.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.6)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.south_west_rounded, size: 10, color: AppColors.brandBlue),
                                            SizedBox(width: 4),
                                            Text(
                                              'Follows you',
                                              style: TextStyle(
                                                fontFamily: 'Overpass',
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.brandBlue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (_isFollowing && !_isFollower)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.north_east_rounded, size: 10, color: Colors.white70),
                                            SizedBox(width: 4),
                                            Text(
                                              'Following',
                                              style: TextStyle(
                                                fontFamily: 'Overpass',
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white70,
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
                                        color: Colors.black.withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$_followingCount',
                                            style: TextStyle(
                                              fontFamily: 'Overpass',
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Following',
                                            style: TextStyle(
                                              fontFamily: 'Overpass',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
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
                                        color: Colors.black.withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$_followersCount',
                                            style: TextStyle(
                                              fontFamily: 'Overpass',
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Followers',
                                            style: TextStyle(
                                              fontFamily: 'Overpass',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
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
                backgroundColor: context.appSurface,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Stats & Visual Charts
                    _buildStatsTab(
                      about: about,
                      animeCount: count,
                      animeDays: days,
                      animeMeanScore: meanScore,
                      animeStdDev: stdDev,
                      animeEpisodes: episodes,
                      animeMinutes: minutes,
                      animeStatuses: animeStatuses,
                      animeScores: scoreList,
                      animeFormats: formatList,
                      animeGenres: genreList,
                      mangaCount: mangaCount,
                      mangaChapters: mangaChapters,
                      mangaVolumes: mangaVolumes,
                      mangaMeanScore: mangaMeanScore,
                      mangaStatuses: mangaStatuses,
                      mangaScores: mangaScores,
                      mangaGenres: mangaGenres,
                      accentColor: accentColor,
                      isOwn: isOwn,
                    ),

                    // Tab 2: Favorites
                    _buildFavoritesTab(
                      favAnime: favAnime,
                      favManga: favManga,
                      favCharacters: favCharacters,
                      favStaff: favStaff,
                      accentColor: accentColor,
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
    String? about,
    required int animeCount,
    required String animeDays,
    required double animeMeanScore,
    required double animeStdDev,
    required int animeEpisodes,
    required int animeMinutes,
    required List<Map<String, dynamic>> animeStatuses,
    required List<Map<String, dynamic>> animeScores,
    required List<Map<String, dynamic>> animeFormats,
    required List<Map<String, dynamic>> animeGenres,
    required int mangaCount,
    required int mangaChapters,
    required int mangaVolumes,
    required double mangaMeanScore,
    required List<Map<String, dynamic>> mangaStatuses,
    required List<Map<String, dynamic>> mangaScores,
    required List<Map<String, dynamic>> mangaGenres,
    required Color accentColor,
    required bool isOwn,
  }) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.p16),
      children: [
        // 1. Expandable About Bio Card
        AniListBioWidget(
          bio: about,
          accentColor: accentColor,
          isOwn: isOwn,
        ),

        // 2. Segmented Pill Switch: Anime Stats vs Manga Stats
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 36,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _statsMode = 'ANIME');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: _statsMode == 'ANIME' ? accentColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _statsMode == 'ANIME'
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        Icon(
                          Icons.tv_rounded,
                          size: 14,
                          color: _statsMode == 'ANIME' ? Colors.white : context.appTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Anime Stats',
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _statsMode == 'ANIME' ? Colors.white : context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _statsMode = 'MANGA');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: _statsMode == 'MANGA' ? accentColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _statsMode == 'MANGA'
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 14,
                          color: _statsMode == 'MANGA' ? Colors.white : context.appTextSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Manga Stats',
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _statsMode == 'MANGA' ? Colors.white : context.appTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_statsMode == 'ANIME') ...[
          // Anime Quick Stat Cards (2x3)
          Row(
            children: [
              _statCard('Total Anime', '$animeCount', Icons.tv_rounded, accentColor, const Color(0xFF3DB4F2)),
              const SizedBox(width: 8),
              _statCard('Days Watched', '${animeDays}d', Icons.access_time_rounded, accentColor, const Color(0xFF00B4D8)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statCard('Mean Score', animeMeanScore > 0 ? '${animeMeanScore.toStringAsFixed(1)}%' : '-', Icons.star_rounded, accentColor, const Color(0xFFFFB703)),
              const SizedBox(width: 8),
              _statCard('Std Dev', animeStdDev > 0 ? animeStdDev.toStringAsFixed(1) : '-', Icons.query_stats_rounded, accentColor, const Color(0xFFE056FD)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statCard('Episodes', '$animeEpisodes', Icons.play_circle_outline_rounded, accentColor, const Color(0xFF06D6A0)),
              const SizedBox(width: 8),
              _statCard('Time Watched', '${(animeMinutes / 60).toStringAsFixed(0)}h', Icons.timer_outlined, accentColor, const Color(0xFF9D4EDD)),
            ],
          ),
          const SizedBox(height: 16),

          // Status Distribution
          if (animeStatuses.isNotEmpty)
            _buildStatusBar(animeStatuses, accentColor, isAnime: true),

          // Score Distribution Histogram
          if (animeScores.isNotEmpty)
            _buildScoreHistogram(animeScores, animeMeanScore, accentColor),

          // Format Breakdown (Donut Chart)
          if (animeFormats.isNotEmpty)
            _buildFormatDonut(animeFormats, animeCount, accentColor),

          // Top Genres Progress Bars
          if (animeGenres.isNotEmpty)
            _buildGenresVisualizer(animeGenres, accentColor),
        ] else ...[
          // Manga Quick Stat Cards (2x2)
          Row(
            children: [
              _statCard('Total Manga', '$mangaCount', Icons.menu_book_rounded, accentColor, const Color(0xFF3DB4F2)),
              const SizedBox(width: 8),
              _statCard('Chapters Read', '$mangaChapters', Icons.auto_stories_rounded, accentColor, const Color(0xFF00B4D8)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statCard('Volumes Read', '$mangaVolumes', Icons.book_rounded, accentColor, const Color(0xFF06D6A0)),
              const SizedBox(width: 8),
              _statCard('Mean Score', mangaMeanScore > 0 ? '${mangaMeanScore.toStringAsFixed(1)}%' : '-', Icons.star_rounded, accentColor, const Color(0xFFFFB703)),
            ],
          ),
          const SizedBox(height: 16),

          // Manga Status Distribution
          if (mangaStatuses.isNotEmpty)
            _buildStatusBar(mangaStatuses, accentColor, isAnime: false),

          // Manga Score Distribution Histogram
          if (mangaScores.isNotEmpty)
            _buildScoreHistogram(mangaScores, mangaMeanScore, accentColor),

          // Manga Top Genres
          if (mangaGenres.isNotEmpty)
            _buildGenresVisualizer(mangaGenres, accentColor),
        ],
      ],
    );
  }

  Widget _buildStatusBar(List<Map<String, dynamic>> statuses, Color accentColor, {required bool isAnime}) {
    final total = statuses.fold<int>(0, (sum, item) => sum + (item['count'] as int? ?? 0));
    if (total == 0) return const SizedBox.shrink();

    Color getStatusColor(String status) {
      switch (status.toUpperCase()) {
        case 'CURRENT':
          return AppColors.statusWatching;
        case 'COMPLETED':
          return AppColors.statusCompleted;
        case 'PLANNING':
          return AppColors.statusPlanning;
        case 'PAUSED':
          return AppColors.statusPaused;
        case 'DROPPED':
          return AppColors.statusDropped;
        case 'REPEATING':
          return AppColors.statusRepeating;
        default:
          return AppColors.brandBlue;
      }
    }

    String getStatusLabel(String status) {
      switch (status.toUpperCase()) {
        case 'CURRENT':
          return isAnime ? 'Watching' : 'Reading';
        case 'COMPLETED':
          return 'Completed';
        case 'PLANNING':
          return 'Planning';
        case 'PAUSED':
          return 'Paused';
        case 'DROPPED':
          return 'Dropped';
        case 'REPEATING':
          return isAnime ? 'Rewatching' : 'Rereading';
        default:
          return status;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
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
                child: Icon(Icons.donut_small_rounded, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Text(
                'Status Distribution',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$total entries',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.appTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Multi-segment horizontal progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: statuses.map((s) {
                  final cnt = s['count'] as int? ?? 0;
                  final status = s['status'] as String? ?? '';
                  final pct = cnt / total;
                  return Expanded(
                    flex: (pct * 1000).toInt().clamp(1, 1000),
                    child: Container(
                      color: getStatusColor(status),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Status Chips with Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: statuses.map((s) {
              final cnt = s['count'] as int? ?? 0;
              final status = s['status'] as String? ?? '';
              final color = getStatusColor(status);
              final label = getStatusLabel(status);
              final pct = ((cnt / total) * 100).toStringAsFixed(1);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$label ($cnt • $pct%)',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHistogram(List<Map<String, dynamic>> scoreList, double meanScore, Color accentColor) {
    final maxCount = scoreList
        .map((e) => (e['count'] as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
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
                  Text(
                    'Score Distribution',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.appTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  meanScore > 0 ? 'Avg: ${meanScore.toStringAsFixed(1)}%' : '10 – 100',
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
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount * 1.25 + 2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.darkCard,
                    tooltipRoundedRadius: 6,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final score = scoreList[group.x]['score'];
                      final count = rod.toY.toInt();
                      return BarTooltipItem(
                        '$score%: $count titles',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
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
                              style: TextStyle(
                                fontFamily: 'Overpass',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: context.appTextSecondary,
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
                    barRods: [
                      BarChartRodData(
                        toY: countVal,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            accentColor.withValues(alpha: 0.65),
                            accentColor,
                          ],
                        ),
                        width: 15,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatDonut(List<Map<String, dynamic>> formatList, int totalCount, Color accentColor) {
    Color getFormatColor(String format) {
      switch (format.toUpperCase()) {
        case 'TV':
          return const Color(0xFF3DB4F2);
        case 'TV_SHORT':
          return const Color(0xFF00B4D8);
        case 'MOVIE':
          return AppColors.statusCompleted;
        case 'OVA':
          return AppColors.statusPaused;
        case 'ONA':
          return const Color(0xFF9D4EDD);
        case 'SPECIAL':
          return AppColors.statusPlanning;
        case 'MANGA':
          return AppColors.statusRepeating;
        default:
          return accentColor;
      }
    }

    final topFormats = formatList.take(6).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
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
              Text(
                'Format Breakdown',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              height: 160,
              width: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 46,
                      sections: topFormats.map((f) {
                        final format = f['format'] as String? ?? '';
                        final cnt = (f['count'] as num?)?.toDouble() ?? 0.0;
                        return PieChartSectionData(
                          value: cnt,
                          showTitle: false,
                          radius: 30,
                          color: getFormatColor(format),
                        );
                      }).toList(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalCount',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        'TITLES',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: context.appTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Format Legend Grid
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: topFormats.map((f) {
              final format = f['format'] as String? ?? '';
              final cnt = f['count'] as int? ?? 0;
              final color = getFormatColor(format);
              final pct = totalCount > 0 ? ((cnt / totalCount) * 100).toStringAsFixed(1) : '0';

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$format ($cnt • $pct%)',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.appTextSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenresVisualizer(List<Map<String, dynamic>> genreList, Color accentColor) {
    final maxCnt = (genreList.first['count'] as num?)?.toDouble() ?? 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
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
              Text(
                'Top Genres',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...genreList.take(7).map((g) {
            final genre = g['genre'] as String? ?? '';
            final cnt = g['count'] as int? ?? 0;
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
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        '$cnt entries',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: context.appBorder,
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
    );
  }

  Widget _buildFavoritesTab({
    required List<Map<String, dynamic>> favAnime,
    required List<Map<String, dynamic>> favManga,
    required List<Map<String, dynamic>> favCharacters,
    required List<Map<String, dynamic>> favStaff,
    required Color accentColor,
  }) {
    final allCount = favAnime.length + favManga.length + favCharacters.length + favStaff.length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.p16),
      children: [
        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFavFilterChip('All ($allCount)', 'ALL', accentColor),
              const SizedBox(width: 8),
              _buildFavFilterChip('Anime (${favAnime.length})', 'ANIME', accentColor),
              const SizedBox(width: 8),
              _buildFavFilterChip('Manga (${favManga.length})', 'MANGA', accentColor),
              const SizedBox(width: 8),
              _buildFavFilterChip('Characters (${favCharacters.length})', 'CHARACTERS', accentColor),
              const SizedBox(width: 8),
              _buildFavFilterChip('Staff (${favStaff.length})', 'STAFF', accentColor),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_favFilter == 'ALL') ...[
          if (favAnime.isNotEmpty)
            _favMediaSection(
              'Favorite Anime',
              favAnime,
              onSeeAll: () => setState(() => _favFilter = 'ANIME'),
            ),
          if (favManga.isNotEmpty)
            _favMediaSection(
              'Favorite Manga',
              favManga,
              onSeeAll: () => setState(() => _favFilter = 'MANGA'),
            ),
          if (favCharacters.isNotEmpty)
            _favPersonSection(
              'Favorite Characters',
              favCharacters,
              isCharacter: true,
              onSeeAll: () => setState(() => _favFilter = 'CHARACTERS'),
            ),
          if (favStaff.isNotEmpty)
            _favPersonSection(
              'Favorite Staff',
              favStaff,
              isCharacter: false,
              onSeeAll: () => setState(() => _favFilter = 'STAFF'),
            ),
        ] else if (_favFilter == 'ANIME') ...[
          _buildMediaGrid(favAnime, 'No Favorite Anime Added Yet'),
        ] else if (_favFilter == 'MANGA') ...[
          _buildMediaGrid(favManga, 'No Favorite Manga Added Yet'),
        ] else if (_favFilter == 'CHARACTERS') ...[
          _buildPersonGrid(favCharacters, isCharacter: true, emptyMessage: 'No Favorite Characters Added Yet'),
        ] else if (_favFilter == 'STAFF') ...[
          _buildPersonGrid(favStaff, isCharacter: false, emptyMessage: 'No Favorite Staff Added Yet'),
        ],

        if (allCount == 0)
          const EmptyView(
            title: 'No Favorites Yet',
            subtitle: 'Heart anime, manga, characters, and staff to showcase them here.',
            icon: Icons.favorite_border_rounded,
          ),
      ],
    );
  }

  Widget _buildFavFilterChip(String label, String key, Color accentColor) {
    final isSelected = _favFilter == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _favFilter = key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.2) : context.appSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : context.appBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Overpass',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? accentColor : context.appTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _favMediaSection(String title, List<Map<String, dynamic>> items, {required VoidCallback onSeeAll}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.appTextPrimary,
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'View All (${items.length}) →',
                style: const TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandBlue,
                ),
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

  Widget _favPersonSection(
    String title,
    List<Map<String, dynamic>> items, {
    required bool isCharacter,
    required VoidCallback onSeeAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.appTextPrimary,
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'View All (${items.length}) →',
                style: const TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandBlue,
                ),
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
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.appTextPrimary,
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

  Widget _buildMediaGrid(List<Map<String, dynamic>> items, String emptyMessage) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            emptyMessage,
            style: TextStyle(fontFamily: 'Overpass', color: context.appTextSecondary),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final media = items[index];
        return MediaCard(
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
        );
      },
    );
  }

  Widget _buildPersonGrid(List<Map<String, dynamic>> items, {required bool isCharacter, required String emptyMessage}) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            emptyMessage,
            style: TextStyle(fontFamily: 'Overpass', color: context.appTextSecondary),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final name = item['name']?['userPreferred'] ?? item['name']?['full'] ?? '';
        final image = item['image']?['large'] ?? item['image']?['medium'] as String?;
        final occupations = (item['primaryOccupations'] as List?)?.cast<String>() ?? [];

        return InkWell(
          borderRadius: BorderRadius.circular(10),
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
          child: Container(
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.appBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: image != null
                        ? AppNetworkImage(imageUrl: image, fit: BoxFit.cover, width: double.infinity)
                        : Icon(Icons.person, color: context.appTextSecondary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                      if (occupations.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          occupations.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 9.5,
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
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accentColor, [Color? iconColor]) {
    final effectiveColor = iconColor ?? accentColor;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.p12),
        decoration: BoxDecoration(
          color: context.appSurface,
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
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
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
      color: context.appBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AnimatedBuilder(
        animation: tabController,
        builder: (context, _) {
          return Row(
            children: [
              _buildPill(context, 0, 'Stats', Icons.bar_chart_rounded),
              const SizedBox(width: 8),
              _buildPill(context, 1, 'Favorites', Icons.favorite_rounded),
              const SizedBox(width: 8),
              _buildPill(context, 2, isOwnProfile ? 'My Activity' : 'Activity', Icons.history_rounded),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPill(BuildContext context, int index, String title, IconData icon) {
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
            color: isSelected ? accentColor : context.appSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? accentColor : context.appBorder,
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
                color: isSelected ? Colors.white : context.appTextSecondary,
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
                  color: isSelected ? Colors.white : context.appTextSecondary,
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
