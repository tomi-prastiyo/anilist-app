import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final auth = ref.read(authControllerProvider);
    if (auth is! Authenticated) {
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
      final profile = await repo.fetchUserProfile(
        userId: auth.user.id,
        userName: auth.user.name,
      );
      if (mounted) {
        setState(() {
          _userProfile = profile;
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isAuthenticated = auth is Authenticated;
    final user = isAuthenticated ? auth.user : null;
    final userName = user?.name ?? 'Guest User';
    final userAvatar = user?.avatarUrl;
    final userBanner = user?.bannerUrl;
    final accentColor = AppColors.getProfileAccentColor(user?.profileColor);

    if (!isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: EmptyView(
          title: 'Sign in to see your profile',
          subtitle: 'View your anime & manga stats, favorite characters, and community activity.',
          icon: Icons.person_outline_rounded,
          action: ElevatedButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign In with AniList'),
          ),
        ),
      );
    }

    if (_errorMessage != null && _userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: ErrorView(
          message: _errorMessage!,
          onRetry: _loadProfile,
        ),
      );
    }

    final stats = _userProfile?['statistics']?['anime'] as Map<String, dynamic>?;
    final mangaStats = _userProfile?['statistics']?['manga'] as Map<String, dynamic>?;
    final count = stats?['count'] as int? ?? 0;
    final minutes = stats?['minutesWatched'] as int? ?? 0;
    final days = (minutes / (60 * 24)).toStringAsFixed(1);
    final meanScore = (stats?['meanScore'] as num?)?.toDouble() ?? 0.0;
    final stdDev = (stats?['standardDeviation'] as num?)?.toDouble() ?? 0.0;
    final episodes = stats?['episodesWatched'] as int? ?? 0;
    final mangaChapters = mangaStats?['chaptersRead'] as int? ?? 0;
    final scoreList = (stats?['scores'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final formatList = (stats?['formats'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final genreList = (stats?['genres'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final favs = _userProfile?['favourites'] as Map<String, dynamic>?;
    final favAnime = (favs?['anime']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final favManga = (favs?['manga']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final favCharacters = (favs?['characters']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final favStaff = (favs?['staff']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (userBanner != null)
                    AppNetworkImage(imageUrl: userBanner, borderRadius: BorderRadius.zero)
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0E2238), Color(0xFF162A44)],
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.darkBackground.withValues(alpha: 0.6),
                          AppColors.darkBackground,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Overlapping rectangular avatar (74x98, 4px top radius, 3px solid border)
                        Container(
                          width: 74,
                          height: 98,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            border: Border.all(color: AppColors.darkSurface, width: 3),
                            color: AppColors.darkSurface,
                            boxShadow: const [
                              BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                            child: userAvatar != null
                                ? AppNetworkImage(imageUrl: userAvatar, fit: BoxFit.cover)
                                : const Icon(Icons.person, size: 36, color: AppColors.darkTextSecondary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'AniList Member',
                                      style: TextStyle(
                                        fontFamily: 'Overpass',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: accentColor,
                labelColor: accentColor,
                unselectedLabelColor: AppColors.darkTextSecondary,
                tabs: const [
                  Tab(text: 'Stats & Charts'),
                  Tab(text: 'Favorites'),
                  Tab(text: 'Activity'),
                ],
              ),
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

                    // Tab 3: Activity Feed
                    const ActivityScreen(),
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
    required List<Map<String, dynamic>> scoreList,
    required List<Map<String, dynamic>> formatList,
    required List<Map<String, dynamic>> genreList,
    required Color accentColor,
  }) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.p16),
      children: [
        // 1. Clean 2x2 Metric Cards (PdBear Authentic Account Stats)
        Row(
          children: [
            _statCard('Total Anime', '$count', Icons.tv_rounded, accentColor),
            const SizedBox(width: 8),
            _statCard('Days Watched', days, Icons.access_time_rounded, accentColor),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard('Mean Score', meanScore > 0 ? '${meanScore.toStringAsFixed(1)}%' : '-', Icons.star_rounded, accentColor),
            const SizedBox(width: 8),
            _statCard('Std Dev', stdDev > 0 ? stdDev.toStringAsFixed(1) : '-', Icons.query_stats_rounded, accentColor),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard('Episodes', '$episodes', Icons.play_circle_outline_rounded, accentColor),
            const SizedBox(width: 8),
            _statCard('Manga Chapters', '$mangaChapters', Icons.menu_book_rounded, accentColor),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Score Distribution Histogram (Scores 10 to 100)
        if (scoreList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(6),
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
                        Icon(Icons.bar_chart_rounded, size: 18, color: accentColor),
                        const SizedBox(width: 6),
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
                    const Text(
                      '10 – 100',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkTextSecondary),
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
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
          const SizedBox(height: 20),
        ],

        // 3. Format Breakdown (Donut Chart)
        if (formatList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, size: 18, color: accentColor),
                    const SizedBox(width: 6),
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
          const SizedBox(height: 20),
        ],

        // 4. Top Genres Breakdown Progress Bars
        if (genreList.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category_rounded, size: 18, color: accentColor),
                    const SizedBox(width: 6),
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
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.darkBorder,
                            color: accentColor,
                            minHeight: 5,
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
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Overpass',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
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
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Overpass',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
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
                child: Column(
                  children: [
                    AppAvatar(imageUrl: image, size: 52),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 65,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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

  Widget _statCard(String label, String value, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.p12),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Overpass',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
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

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _ProfileTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.darkBackground,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_ProfileTabBarDelegate oldDelegate) => false;
}
