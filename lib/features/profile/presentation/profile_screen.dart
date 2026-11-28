import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/yuyuyu_assets.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/image/app_network_image.dart';
import '../../../shared/state/favourite_sync_store.dart';
import '../../../shared/widgets/notification_bell_button.dart';
import '../../activity/presentation/activity_screen.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/profile_repository.dart';
import 'user_follows_screen.dart';
import 'widgets/profile_favorites_tab.dart';
import 'widgets/profile_stats_tab.dart';
import 'widgets/reorder_favorites_sheet.dart';

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

  Future<void> _loadProfile({bool silent = false}) async {
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

    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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
    final themeMode = ref.watch(themeModeProvider);
    final activeHeroine = ref.watch(yuyuyuHeroineProvider);
    final themeBrightness = Theme.of(context).brightness;
    final themePalette = context.appPalette;
    final statsThemeKey = ValueKey(
      'stats_${themeMode.name}_${activeHeroine.id}_${themeBrightness.name}',
    );
    final isAuthenticated = auth is Authenticated;
    final authUser = isAuthenticated ? auth.user : null;
    final isOwn = _isOwnProfile(authUser);

    ref.watch(favoritesRevisionProvider);
    ref.listen<int>(favoritesRevisionProvider, (prev, next) {
      if (mounted && isOwn && isAuthenticated) {
        _loadProfile(silent: true);
      }
    });

    // Unauthenticated viewing own profile
    if (isOwn && !isAuthenticated) {
      return Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: EmptyView(
          title: 'Sign in to see your profile',
          subtitle: 'View your anime & manga stats, favorites, friends, and personal activity.',
          icon: Icons.person_outline_rounded,
          action: Builder(
            builder: (context) {
              final ctaColor = context.isYuYuYu ? context.appAccent : AppColors.brandBlue;
              return ElevatedButton(
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctaColor,
                  foregroundColor: ctaColor.computeLuminance() > 0.55 ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Sign In with AniList'),
              );
            },
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
    final aboutHtml = _userProfile?['aboutHtml'] as String?;

    // Favourites
    final favs = _userProfile?['favourites'] as Map<String, dynamic>?;
    final rawFavAnime = (favs?['anime']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final rawFavManga = (favs?['manga']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final rawFavCharacters = (favs?['characters']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final rawFavStaff = (favs?['staff']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final favStudios = (favs?['studios']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final favSync = ref.watch(favouriteSyncStoreProvider);
    final favAnime = isOwn ? favSync.applyToList(FavouriteKind.anime, rawFavAnime) : rawFavAnime;
    final favManga = isOwn ? favSync.applyToList(FavouriteKind.manga, rawFavManga) : rawFavManga;
    final favCharacters = isOwn ? favSync.applyToList(FavouriteKind.character, rawFavCharacters) : rawFavCharacters;
    final favStaff = isOwn ? favSync.applyToList(FavouriteKind.staff, rawFavStaff) : rawFavStaff;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 245,
            pinned: true,
            backgroundColor: context.appBackground,
            title: innerBoxIsScrolled
                ? Row(
                    children: [
                      if (userAvatar != null) ...[
                        ClipOval(
                          child: AppNetworkImage(
                            imageUrl: userAvatar,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          userName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: context.appTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
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
                    const NotificationBellButton(darkBackdrop: true),
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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: context.isYuYuYu
                              ? const [YuYuYuAssets.twilightCard, YuYuYuAssets.jukaiGlow]
                              : const [Color(0xFF0E2238), Color(0xFF162A44)],
                        ),
                      ),
                    ),
                  // Dark Multi-stop Gradient Scrim (includes top scrim for status bar legibility)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.48),
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        stops: const [0.0, 0.28, 0.65, 1.0],
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
                            border: Border.all(
                              color: context.isYuYuYu
                                  ? YuYuYuAssets.shinjuGold.withValues(alpha: 0.85)
                                  : context.appSurface,
                              width: context.isYuYuYu ? 3.0 : 3.5,
                            ),
                            color: context.appSurface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                              if (context.isYuYuYu)
                                BoxShadow(
                                  color: context.appAccent.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                )
                              else
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
              brightness: themeBrightness,
              palette: themePalette,
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
                    ProfileStatsTab(
                      key: statsThemeKey,
                      about: about,
                      aboutHtml: aboutHtml,
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
                      onSaveBio: isOwn
                          ? (newBio) async {
                              try {
                                final res = await ref
                                    .read(profileRepositoryProvider)
                                    .updateUserBio(newBio);
                                if (mounted) {
                                  setState(() {
                                    _userProfile?['about'] = res['about'] ?? newBio;
                                    _userProfile?['aboutHtml'] = res['aboutHtml'];
                                  });
                                }
                                return true;
                              } catch (e) {
                                if (mounted && this.context.mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update bio: $e'),
                                      backgroundColor: AppColors.statusDropped,
                                    ),
                                  );
                                }
                                return false;
                              }
                            }
                          : null,
                    ),

                    // Tab 2: Favorites
                    ProfileFavoritesTab(
                      favAnime: favAnime,
                      favManga: favManga,
                      favCharacters: favCharacters,
                      favStaff: favStaff,
                      favStudios: favStudios,
                      accentColor: accentColor,
                      canReorder: isOwn && isAuthenticated,
                      onOpenReorder: (initialCategory) => _openReorderFavorites(
                        initialCategory: initialCategory,
                        favAnime: favAnime,
                        favManga: favManga,
                        favCharacters: favCharacters,
                        favStaff: favStaff,
                        favStudios: favStudios,
                        accentColor: accentColor,
                      ),
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

  void _openReorderFavorites({
    required String initialCategory,
    required List<Map<String, dynamic>> favAnime,
    required List<Map<String, dynamic>> favManga,
    required List<Map<String, dynamic>> favCharacters,
    required List<Map<String, dynamic>> favStaff,
    required List<Map<String, dynamic>> favStudios,
    required Color accentColor,
  }) {
    final repo = ref.read(profileRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReorderFavoritesSheet(
        repo: repo,
        accentColor: accentColor,
        initialCategory: initialCategory,
        favAnime: favAnime,
        favManga: favManga,
        favCharacters: favCharacters,
        favStaff: favStaff,
        favStudios: favStudios,
        onSaved: (categoryKey, updated) {
          final favs = _userProfile?['favourites'];
          if (favs is! Map) return;
          const keyMap = {
            'ANIME': 'anime',
            'MANGA': 'manga',
            'CHARACTERS': 'characters',
            'STAFF': 'staff',
            'STUDIOS': 'studios',
          };
          final nodeKey = keyMap[categoryKey];
          if (nodeKey != null && favs[nodeKey] is Map && mounted) {
            setState(() {
              favs[nodeKey]['nodes'] = updated;
            });
          }
        },
      ),
    );
  }
}

class _ProfilePillTabsDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final Color accentColor;
  final bool isOwnProfile;
  final Brightness brightness;
  final AppThemePalette palette;

  _ProfilePillTabsDelegate({
    required this.tabController,
    required this.accentColor,
    required this.isOwnProfile,
    required this.brightness,
    required this.palette,
  });

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

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
          padding: const EdgeInsets.symmetric(horizontal: 6),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : context.appTextSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Overpass',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : context.appTextSecondary,
                  ),
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
        oldDelegate.tabController != tabController ||
        oldDelegate.brightness != brightness ||
        oldDelegate.palette != palette;
  }
}
