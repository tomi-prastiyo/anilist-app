import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/text_util.dart';
import '../../../shared/badges/format_chip.dart';
import '../../../shared/badges/score_badge.dart';
import '../../../shared/badges/status_chip.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/image/app_avatar.dart';
import '../../../shared/image/app_network_image.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../character_staff/presentation/staff_detail_screen.dart';
import '../../media_editor/presentation/media_editor_bottom_sheet.dart';
import '../data/media_detail_repository.dart';
import 'widgets/character_dual_card.dart';
import 'widgets/media_info_grid.dart';
import 'widgets/media_mutual_friends_card.dart';
import 'widgets/media_theme_songs_card.dart';

class MediaDetailScreen extends ConsumerStatefulWidget {
  final int mediaId;

  const MediaDetailScreen({
    super.key,
    required this.mediaId,
  });

  @override
  ConsumerState<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends ConsumerState<MediaDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _mediaData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavourite = false;

  // Themes state
  Map<String, List<Map<String, dynamic>>> _themes = {
    'openings': [],
    'endings': [],
    'insertSongs': [],
  };
  bool _isLoadingThemes = false;

  // UI state
  bool _isSynopsisExpanded = false;
  String _characterFilter = 'ALL'; // 'ALL', 'MAIN', 'SUPPORTING'
  List<Map<String, dynamic>> _followingFriends = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(mediaDetailRepositoryProvider);
      final data = await repo.fetchMediaDetail(widget.mediaId);
      final friends = await repo.fetchFollowingMediaList(widget.mediaId);
      if (mounted) {
        setState(() {
          _mediaData = data;
          _isFavourite = data['isFavourite'] as bool? ?? false;
          _followingFriends = friends;
          _isLoading = false;
        });

        // If anime, asynchronously load theme songs in background
        final type = data['type'] as String?;
        if (type == 'ANIME') {
          _loadThemes(data['id'] as int, TextUtil.getPreferredTitle(data['title']));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadThemes(int anilistId, String title) async {
    setState(() => _isLoadingThemes = true);
    try {
      final repo = ref.read(mediaDetailRepositoryProvider);
      final themes = await repo.fetchMediaThemes(
        anilistId: anilistId,
        queryTitle: title,
      );
      if (mounted) {
        setState(() {
          _themes = themes;
          _isLoadingThemes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingThemes = false);
    }
  }

  Future<void> _toggleFavourite() async {
    HapticFeedback.lightImpact();
    final type = _mediaData?['type'] as String?;
    setState(() => _isFavourite = !_isFavourite);
    try {
      final repo = ref.read(mediaDetailRepositoryProvider);
      await repo.toggleFavourite(
        animeId: type == 'ANIME' ? widget.mediaId : null,
        mangaId: type == 'MANGA' ? widget.mediaId : null,
      );
    } catch (e) {
      // Revert if error
      if (mounted) setState(() => _isFavourite = !_isFavourite);
    }
  }

  void _openEditor() {
    if (_mediaData == null) return;
    final type = _mediaData!['type'] as String? ?? 'ANIME';
    final episodes = _mediaData!['episodes'] as int?;
    final chapters = _mediaData!['chapters'] as int?;
    final currentEntry = _mediaData!['mediaListEntry'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaEditorBottomSheet(
        mediaId: widget.mediaId,
        mediaType: type,
        maxCount: episodes ?? chapters,
        initialEntry: currentEntry,
        onSaved: _loadMedia,
      ),
    );
  }

  String _formatEntryStatus(String? status) {
    if (status == null) return '';
    return status[0] + status.substring(1).toLowerCase();
  }

  Future<void> _launchExternalUrl(String url) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brandBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(backgroundColor: context.appBackground),
        body: ErrorView(message: _errorMessage!, onRetry: _loadMedia),
      );
    }

    final media = _mediaData!;
    final title = TextUtil.getPreferredTitle(media['title']);
    final bannerUrl = media['bannerImage'] as String?;
    final coverUrl = media['coverImage']?['extraLarge'] ?? media['coverImage']?['large'];
    final format = media['format'] as String?;
    final status = media['status'] as String?;
    final score = (media['averageScore'] as num?)?.toDouble();
    final entry = media['mediaListEntry'] as Map<String, dynamic>?;

    final authState = ref.watch(authControllerProvider);
    final isAuthenticated = authState is Authenticated;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 270,
            pinned: true,
            backgroundColor: context.appSurface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (isAuthenticated)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isFavourite ? AppColors.favoritePink : Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: _toggleFavourite,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (bannerUrl != null)
                    AppNetworkImage(imageUrl: bannerUrl, borderRadius: BorderRadius.zero)
                  else if (coverUrl != null)
                    AppNetworkImage(imageUrl: coverUrl, borderRadius: BorderRadius.zero),
                  // Dark gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          context.appBackground.withValues(alpha: 0.75),
                          context.appBackground,
                        ],
                      ),
                    ),
                  ),
                  // Poster + Title Bar
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppNetworkImage(
                          imageUrl: coverUrl,
                          width: 86,
                          height: 124,
                          borderRadius: AppSpacing.borderRadius8,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              if ((media['title']?['english'] as String?) != null &&
                                  (media['title']?['english'] as String).isNotEmpty &&
                                  media['title']?['english'] != title) ...[
                                const SizedBox(height: 2),
                                Text(
                                  media['title']['english'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: context.appTextSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (format != null) FormatChip(format: format),
                                  if (status != null) StatusChip(status: status),
                                  if (score != null) ScoreBadge(score: score),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isAuthenticated ? _openEditor : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: entry != null ? AppColors.statusCompleted : AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadius12),
                      ),
                      icon: Icon(entry != null ? Icons.edit_rounded : Icons.add_rounded, size: 18),
                      label: Text(
                        entry != null
                            ? 'In List: ${_formatEntryStatus(entry['status'])} (${entry['progress'] ?? 0})'
                            : (isAuthenticated ? 'Add to List' : 'Sign in to add to list'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.brandBlue,
                indicatorWeight: 3,
                labelColor: AppColors.brandBlue,
                unselectedLabelColor: context.appTextSecondary,
                labelStyle: const TextStyle(fontFamily: 'Overpass', fontWeight: FontWeight.w800, fontSize: 13.5),
                unselectedLabelStyle: const TextStyle(fontFamily: 'Overpass', fontWeight: FontWeight.w600, fontSize: 13.5),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Characters'),
                  Tab(text: 'Staff'),
                  Tab(text: 'Relations'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(media),
            _buildCharactersTab(media),
            _buildStaffTab(media),
            _buildRelationsTab(media),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> media) {
    final rawDescription = TextUtil.stripHtml(media['description'] as String?);
    final isAnime = media['type'] == 'ANIME';
    final tags = (media['tags'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final externalLinks = (media['externalLinks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final recNodes = (media['recommendations']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final title = TextUtil.getPreferredTitle(media['title']);
    final titleObj = media['title'] as Map<String, dynamic>?;
    final romajiTitle = titleObj?['romaji'] as String?;
    final englishTitle = titleObj?['english'] as String?;
    final nativeTitle = titleObj?['native'] as String?;
    final synonyms = (media['synonyms'] as List?)?.cast<String>() ?? [];

    // Synopsis truncation logic
    final isLongSynopsis = rawDescription.length > 250;
    final displayDescription = (!isLongSynopsis || _isSynopsisExpanded)
        ? rawDescription
        : '${rawDescription.substring(0, 250)}...';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Mutual Friends Activity
        if (_followingFriends.isNotEmpty)
          MediaMutualFriendsCard(friends: _followingFriends, isAnime: isAnime),

        // Synopsis Section
        if (rawDescription.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Synopsis',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
              if (isLongSynopsis)
                GestureDetector(
                  onTap: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
                  child: Text(
                    _isSynopsisExpanded ? 'Show Less' : 'Read More',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          MarkdownBody(
            data: displayDescription,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 13.5,
                color: context.appTextSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Media Info Grid (Structured 2-column details)
        Text(
          'Information',
          style: TextStyle(
            fontFamily: 'Overpass',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        MediaInfoGrid(media: media),
        const SizedBox(height: 18),

        // Alternative Titles Section (All Versions: Romaji, English, Native, Synonyms)
        _buildTitlesCard(
          romaji: romajiTitle,
          english: englishTitle,
          native: nativeTitle,
          synonyms: synonyms,
        ),

        // Opening & Ending Theme Songs (for Anime)
        if (isAnime) ...[
          MediaThemeSongsCard(
            animeTitle: title,
            openings: _themes['openings'] ?? [],
            endings: _themes['endings'] ?? [],
            insertSongs: _themes['insertSongs'] ?? [],
            isLoading: _isLoadingThemes,
          ),
          const SizedBox(height: 18),
        ],

        // Tags with percentage rank
        if (tags.isNotEmpty) ...[
          Text(
            'Tags',
            style: TextStyle(
              fontFamily: 'Overpass',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.take(12).map((tag) {
              final name = tag['name'] as String? ?? '';
              final rank = tag['rank'] as int? ?? 0;
              final isSpoiler = tag['isMediaSpoiler'] as bool? ?? false;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isSpoiler
                      ? AppColors.statusDropped.withValues(alpha: 0.15)
                      : context.appCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSpoiler
                        ? AppColors.statusDropped.withValues(alpha: 0.4)
                        : context.appBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSpoiler ? AppColors.statusDropped : context.appTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$rank%',
                      style: const TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
        ],

        // External Links
        if (externalLinks.isNotEmpty) ...[
          Text(
            'External Links',
            style: TextStyle(
              fontFamily: 'Overpass',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: externalLinks.map((link) {
              final site = link['site'] as String? ?? 'Link';
              final url = link['url'] as String? ?? '';
              return InkWell(
                onTap: url.isNotEmpty ? () => _launchExternalUrl(url) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: context.appCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.open_in_new_rounded, size: 13, color: AppColors.brandBlue),
                      const SizedBox(width: 6),
                      Text(
                        site,
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
        ],

        // Recommendations Carousel
        if (recNodes.isNotEmpty) ...[
          Text(
            'Community Recommendations',
            style: TextStyle(
              fontFamily: 'Overpass',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.appTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 175,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recNodes.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final recMedia = recNodes[index]['mediaRecommendation'] as Map<String, dynamic>?;
                if (recMedia == null) return const SizedBox.shrink();
                final recId = recMedia['id'] as int?;
                final recTitle = TextUtil.getPreferredTitle(recMedia['title']);
                final recCover = recMedia['coverImage']?['medium'] as String?;
                final recScore = (recMedia['averageScore'] as num?)?.toDouble();

                return GestureDetector(
                  onTap: recId != null
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MediaDetailScreen(mediaId: recId),
                            ),
                          );
                        }
                      : null,
                  child: SizedBox(
                    width: 105,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                           children: [
                            AppNetworkImage(
                              imageUrl: recCover,
                              width: 105,
                              height: 135,
                              borderRadius: AppSpacing.borderRadius8,
                            ),
                            if (recScore != null)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${recScore.toInt()}%',
                                    style: const TextStyle(
                                      fontFamily: 'Overpass',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFFFB703),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: context.appTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildCharactersTab(Map<String, dynamic> media) {
    final edges = (media['characters']?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (edges.isEmpty) {
      return Center(
        child: Text(
          'No character information available.',
          style: TextStyle(fontFamily: 'Overpass', color: context.appTextSecondary),
        ),
      );
    }

    final mainCount = edges.where((e) => (e['role'] as String? ?? '').toUpperCase() == 'MAIN').length;
    final supportCount = edges.length - mainCount;

    final filteredEdges = edges.where((e) {
      if (_characterFilter == 'ALL') return true;
      final role = (e['role'] as String? ?? '').toUpperCase();
      return role == _characterFilter;
    }).toList();

    return Column(
      children: [
        // Filter Pills
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 6),
          child: Row(
            children: [
              _charFilterPill('All (${edges.length})', 'ALL'),
              const SizedBox(width: 8),
              _charFilterPill('Main ($mainCount)', 'MAIN'),
              const SizedBox(width: 8),
              _charFilterPill('Supporting ($supportCount)', 'SUPPORTING'),
            ],
          ),
        ),

        // Characters list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filteredEdges.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final edge = filteredEdges[index];
              final char = edge['node'] as Map<String, dynamic>? ?? {};
              final role = edge['role'] as String? ?? 'SUPPORTING';
              final vaList = (edge['voiceActors'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final va = vaList.isNotEmpty ? vaList.first : null;

              return CharacterDualCard(
                character: char,
                role: role,
                voiceActor: va,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _charFilterPill(String title, String filterKey) {
    final isSelected = _characterFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _characterFilter = filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandBlue.withValues(alpha: 0.2) : context.appCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.brandBlue : context.appBorder,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Overpass',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.brandBlue : context.appTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStaffTab(Map<String, dynamic> media) {
    final staffEdges = (media['staff']?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (staffEdges.isEmpty) {
      return Center(
        child: Text(
          'No staff information available.',
          style: TextStyle(fontFamily: 'Overpass', color: context.appTextSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: staffEdges.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final edge = staffEdges[index];
        final staff = edge['node'] as Map<String, dynamic>?;
        final role = edge['role'] as String? ?? 'Staff';
        final name = staff?['name']?['userPreferred'] ?? staff?['name']?['full'] ?? 'Unknown';
        final image = staff?['image']?['medium'] as String?;
        final staffId = staff?['id'] as int?;

        return InkWell(
          onTap: staffId != null
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => StaffDetailScreen(staffId: staffId),
                    ),
                  );
                }
              : null,
          borderRadius: AppSpacing.borderRadius12,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: AppSpacing.borderRadius12,
              border: Border.all(color: context.appBorder),
              boxShadow: [
                BoxShadow(
                  color: context.isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                AppAvatar(imageUrl: image, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Overpass',
                            color: AppColors.brandBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: context.appTextMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRelationsTab(Map<String, dynamic> media) {
    final relations = (media['relations']?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (relations.isEmpty) {
      return Center(
        child: Text(
          'No relations found.',
          style: TextStyle(fontFamily: 'Overpass', color: context.appTextSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: relations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final rel = relations[index];
        final relType = rel['relationType'] as String? ?? '';
        final relNode = rel['node'] as Map<String, dynamic>?;
        final relTitle = TextUtil.getPreferredTitle(relNode?['title']);
        final relCover = relNode?['coverImage']?['medium'] as String?;
        final relFormat = relNode?['format'] as String?;
        final relStatus = relNode?['status'] as String?;

        return InkWell(
          onTap: () {
            final relId = relNode?['id'] as int?;
            if (relId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MediaDetailScreen(mediaId: relId),
                ),
              );
            }
          },
          borderRadius: AppSpacing.borderRadius12,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: AppSpacing.borderRadius12,
              border: Border.all(color: context.appBorder),
              boxShadow: [
                BoxShadow(
                  color: context.isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                AppNetworkImage(
                  imageUrl: relCover,
                  width: 50,
                  height: 70,
                  borderRadius: AppSpacing.borderRadius8,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          relType.replaceAll('_', ' '),
                          style: const TextStyle(
                            fontFamily: 'Overpass',
                            color: AppColors.brandBlue,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        relTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (relFormat != null) FormatChip(format: relFormat),
                          if (relFormat != null && relStatus != null) const SizedBox(width: 6),
                          if (relStatus != null) StatusChip(status: relStatus),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: context.appTextMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitlesCard({
    String? romaji,
    String? english,
    String? native,
    List<String> synonyms = const [],
  }) {
    final hasTitles = (romaji != null && romaji.isNotEmpty) ||
        (english != null && english.isNotEmpty) ||
        (native != null && native.isNotEmpty) ||
        synonyms.isNotEmpty;
    if (!hasTitles) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: context.isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.translate_rounded, size: 16, color: AppColors.brandBlue),
              ),
              const SizedBox(width: 8),
              Text(
                'Alternative Titles',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (romaji != null && romaji.isNotEmpty)
            _buildTitleRow('Romaji', romaji),
          if (english != null && english.isNotEmpty)
            _buildTitleRow('English', english),
          if (native != null && native.isNotEmpty)
            _buildTitleRow('Native', native),
          if (synonyms.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Synonyms',
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.appTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: synonyms.map((syn) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.appBorder),
                ),
                child: Text(
                  syn,
                  style: TextStyle(
                    fontFamily: 'Overpass',
                    fontSize: 11.5,
                    color: context.appTextPrimary,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.appTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.appTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: context.appBackground,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
