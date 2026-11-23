import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/text_util.dart';
import '../../../shared/badges/format_chip.dart';
import '../../../shared/badges/score_badge.dart';
import '../../../shared/badges/status_chip.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/image/app_avatar.dart';
import '../../../shared/image/app_network_image.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../character_staff/presentation/character_detail_screen.dart';
import '../../character_staff/presentation/staff_detail_screen.dart';
import '../../media_editor/presentation/media_editor_bottom_sheet.dart';
import '../data/media_detail_repository.dart';

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
      setState(() {
        _mediaData = data;
        _isFavourite = data['isFavourite'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavourite() async {
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
      setState(() => _isFavourite = !_isFavourite);
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brandBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(),
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
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
                          AppColors.darkBackground.withValues(alpha: 0.7),
                          AppColors.darkBackground,
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
                          width: 85,
                          height: 120,
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
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
                labelColor: AppColors.brandBlue,
                unselectedLabelColor: AppColors.darkTextSecondary,
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

  String _formatEntryStatus(String? status) {
    if (status == null) return '';
    return status[0] + status.substring(1).toLowerCase();
  }

  Widget _buildOverviewTab(Map<String, dynamic> media) {
    final description = TextUtil.stripHtml(media['description'] as String?);
    final genres = (media['genres'] as List?)?.cast<String>() ?? [];
    final startDate = DateUtil.formatFuzzyDate(media['startDate'] as Map<String, dynamic>?);
    final season = media['season'] as String?;
    final seasonYear = media['seasonYear'] as int?;
    final episodes = media['episodes'] as int?;
    final duration = media['duration'] as int?;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.p16),
      children: [
        if (description.isNotEmpty) ...[
          const Text(
            'Synopsis',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          MarkdownBody(
            data: description,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: const TextStyle(fontSize: 14, color: AppColors.darkTextSecondary, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(AppSpacing.p16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: AppSpacing.borderRadius12,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            children: [
              _infoRow('Format', media['format'] ?? '?'),
              _infoRow('Episodes', episodes?.toString() ?? '?'),
              if (duration != null) _infoRow('Episode Duration', '$duration mins'),
              _infoRow('Status', media['status'] ?? '?'),
              _infoRow('Season', season != null ? '$season ${seasonYear ?? ''}' : '?'),
              _infoRow('Start Date', startDate),
              if (genres.isNotEmpty) _infoRow('Genres', genres.join(', ')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharactersTab(Map<String, dynamic> media) {
    final characters = (media['characters']?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (characters.isEmpty) {
      return const Center(child: Text('No character information available.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.p16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final char = characters[index];
        final name = char['name']?['userPreferred'] ?? char['name']?['full'] ?? 'Unknown';
        final image = char['image']?['medium'] as String?;

        return InkWell(
          onTap: () {
            final charId = char['id'] as int?;
            if (charId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CharacterDetailScreen(characterId: charId),
                ),
              );
            }
          },
          borderRadius: AppSpacing.borderRadius8,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: AppSpacing.borderRadius8,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                AppAvatar(imageUrl: image, size: 48),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffTab(Map<String, dynamic> media) {
    final staffEdges = (media['staff']?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (staffEdges.isEmpty) {
      return const Center(child: Text('No staff information available.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.p16),
      itemCount: staffEdges.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final edge = staffEdges[index];
        final staff = edge['node'] as Map<String, dynamic>?;
        final role = edge['role'] as String? ?? 'Staff';
        final name = staff?['name']?['userPreferred'] ?? staff?['name']?['full'] ?? 'Unknown';
        final image = staff?['image']?['medium'] as String?;

        return InkWell(
          onTap: () {
            final staffId = staff?['id'] as int?;
            if (staffId != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StaffDetailScreen(staffId: staffId),
                ),
              );
            }
          },
          borderRadius: AppSpacing.borderRadius8,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: AppSpacing.borderRadius8,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                AppAvatar(imageUrl: image, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(role, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11.5)),
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

  Widget _buildRelationsTab(Map<String, dynamic> media) {
    final relations = (media['relations']?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (relations.isEmpty) {
      return const Center(child: Text('No relations found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.p16),
      itemCount: relations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final rel = relations[index];
        final relType = rel['relationType'] as String? ?? '';
        final relNode = rel['node'] as Map<String, dynamic>?;
        final relTitle = TextUtil.getPreferredTitle(relNode?['title']);
        final relCover = relNode?['coverImage']?['medium'] as String?;
        final relFormat = relNode?['format'] as String?;

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
          borderRadius: AppSpacing.borderRadius8,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: AppSpacing.borderRadius8,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                AppNetworkImage(
                  imageUrl: relCover,
                  width: 45,
                  height: 60,
                  borderRadius: AppSpacing.borderRadius4,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        relType.replaceAll('_', ' '),
                        style: const TextStyle(color: AppColors.brandBlue, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        relTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (relFormat != null) ...[
                        const SizedBox(height: 4),
                        FormatChip(format: relFormat),
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
      color: AppColors.darkBackground,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
