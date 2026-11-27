import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/text_util.dart';
import '../../../shared/badges/format_chip.dart';
import '../../../shared/badges/score_badge.dart';
import '../../../shared/badges/status_chip.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/image/app_network_image.dart';
import '../../../shared/state/favourite_sync_store.dart';
import '../../../shared/widgets/favourite_icon_button.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media_editor/presentation/media_editor_bottom_sheet.dart';
import '../../profile/data/profile_repository.dart';
import '../data/media_detail_repository.dart';
import 'widgets/media_detail_tabs.dart';
import 'widgets/media_info_grid.dart';
import 'widgets/media_mutual_friends_card.dart';
import 'widgets/media_overview_sections.dart';
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
  bool _isTogglingFavourite = false;

  // Themes state
  Map<String, List<Map<String, dynamic>>> _themes = {
    'openings': [],
    'endings': [],
    'insertSongs': [],
  };
  bool _isLoadingThemes = false;

  // UI state
  bool _isSynopsisExpanded = false;
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
        final mediaType = data['type'] as String?;
        final kind = mediaType == 'MANGA' ? FavouriteKind.manga : FavouriteKind.anime;
        final resolvedFav = ref.read(favouriteSyncStoreProvider).resolve(
              kind,
              widget.mediaId,
              data['isFavourite'] as bool? ?? false,
            );
        setState(() {
          _mediaData = data;
          _isFavourite = resolvedFav;
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
    if (_isTogglingFavourite) return;
    final type = _mediaData?['type'] as String?;
    if (type != 'ANIME' && type != 'MANGA') return;

    HapticFeedback.lightImpact();
    final previous = _isFavourite;
    setState(() {
      _isTogglingFavourite = true;
      _isFavourite = !previous;
    });
    try {
      final repo = ref.read(mediaDetailRepositoryProvider);
      await repo.toggleFavourite(
        animeId: type == 'ANIME' ? widget.mediaId : null,
        mangaId: type == 'MANGA' ? widget.mediaId : null,
      );
      if (mounted) {
        final kind = type == 'MANGA' ? FavouriteKind.manga : FavouriteKind.anime;
        _mediaData?['isFavourite'] = _isFavourite;
        ref.read(favouriteSyncStoreProvider).record(
              kind,
              widget.mediaId,
              _isFavourite,
              itemPreview: _mediaData,
            );
        ref.read(favoritesRevisionProvider.notifier).state++;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavourite = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: $e'),
            backgroundColor: AppColors.statusBehind,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingFavourite = false);
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
            expandedHeight: 295,
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
                FavouriteIconButton(
                  isFavourite: _isFavourite,
                  isToggling: _isTogglingFavourite,
                  useDarkBackdrop: true,
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
                  // Dark gradient overlay (top status-bar scrim + bottom fade)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.25, 0.65, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                          context.appBackground.withValues(alpha: 0.78),
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
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: AppSpacing.borderRadius8,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: AppNetworkImage(
                            imageUrl: coverUrl,
                            width: 96,
                            height: 138,
                            borderRadius: AppSpacing.borderRadius8,
                          ),
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
                        backgroundColor: entry != null ? AppColors.statusCompleted : context.appAccent,
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
                indicatorColor: context.appAccent,
                indicatorWeight: 3,
                labelColor: context.appAccent,
                unselectedLabelColor: context.appTextSecondary,
                labelPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(fontFamily: 'Overpass', fontWeight: FontWeight.w800, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontFamily: 'Overpass', fontWeight: FontWeight.w600, fontSize: 13),
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
            MediaCharactersTab(media: media),
            MediaStaffTab(media: media),
            MediaRelationsTab(media: media),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> media) {
    final rawDescription = TextUtil.stripHtml(media['description'] as String?);
    final isAnime = media['type'] == 'ANIME';
    final tags = (media['tags'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final rankings = (media['rankings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final trailer = media['trailer'] as Map<String, dynamic>?;
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
                      color: context.appAccent,
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

        // Official Rankings Highlights
        if (rankings.isNotEmpty) ...[
          MediaRankingsStrip(rankings: rankings),
          const SizedBox(height: 18),
        ],

        // Official Trailer Card (YouTube)
        if (trailer != null &&
            (trailer['site'] as String?)?.toLowerCase() == 'youtube' &&
            (trailer['id'] as String?)?.isNotEmpty == true) ...[
          MediaTrailerCard(trailer: trailer),
          const SizedBox(height: 18),
        ],

        // Alternative Titles Section (All Versions: Romaji, English, Native, Synonyms)
        MediaTitlesCard(
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
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: context.appAccent,
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
            height: 208,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recNodes.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final recMedia = recNodes[index]['mediaRecommendation'] as Map<String, dynamic>?;
                if (recMedia == null) return const SizedBox.shrink();
                final recId = recMedia['id'] as int?;
                final recTitle = TextUtil.getPreferredTitle(recMedia['title']);
                final recCover = (recMedia['coverImage']?['large'] ?? recMedia['coverImage']?['medium']) as String?;
                final recScore = (recMedia['averageScore'] as num?)?.toDouble();

                return GestureDetector(
                  onTap: recId != null
                      ? () {
                          Navigator.of(context).push(
                            AppPageRoute(page: MediaDetailScreen(mediaId: recId)),
                          );
                        }
                      : null,
                  child: SizedBox(
                    width: 112,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                           children: [
                            AppNetworkImage(
                              imageUrl: recCover,
                              width: 112,
                              height: 154,
                              borderRadius: BorderRadius.circular(10),
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
