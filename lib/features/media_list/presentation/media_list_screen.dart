import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/text_util.dart';
import '../../../shared/cards/media_card.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/widgets/random_pick_sheet.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import 'media_list_controller.dart';

enum ListSortOption {
  updatedAt('Last Updated'),
  score('Score'),
  title('Title (A-Z)'),
  progress('Progress');

  final String label;
  const ListSortOption(this.label);
}

class MediaListScreen extends ConsumerStatefulWidget {
  final String type; // ANIME or MANGA

  const MediaListScreen({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends ConsumerState<MediaListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  MediaCardMode _cardMode = MediaCardMode.list; // Model 1 Neo-Card as default
  String _searchQuery = '';
  bool _isSearchVisible = false;
  ListSortOption _selectedSort = ListSortOption.updatedAt;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // Reordered: Active tracking first (Watching/Reading & Rewatching/Rereading), then Planning, Completed, Paused, Dropped
  final List<String> _statuses = [
    'CURRENT',    // Watching / Reading
    'REPEATING',  // Rewatching / Rereading
    'PLANNING',   // Planning
    'COMPLETED',  // Completed
    'PAUSED',     // Paused
    'DROPPED',    // Dropped
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _selectedTabIndex != _tabController.index) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _getStatusLabel(String status) {
    if (widget.type == 'ANIME') {
      if (status == 'CURRENT') return 'Watching';
      if (status == 'REPEATING') return 'Rewatching';
    } else {
      if (status == 'CURRENT') return 'Reading';
      if (status == 'REPEATING') return 'Rereading';
    }
    return status[0] + status.substring(1).toLowerCase();
  }

  IconData _getLayoutIcon() {
    switch (_cardMode) {
      case MediaCardMode.list:
        return Icons.view_headline_rounded;
      case MediaCardMode.compact:
        return Icons.grid_view_rounded;
      case MediaCardMode.grid:
        return Icons.table_rows_rounded;
    }
  }

  void _cycleLayoutMode() {
    HapticFeedback.lightImpact();
    setState(() {
      switch (_cardMode) {
        case MediaCardMode.list:
          _cardMode = MediaCardMode.compact;
          break;
        case MediaCardMode.compact:
          _cardMode = MediaCardMode.grid;
          break;
        case MediaCardMode.grid:
          _cardMode = MediaCardMode.list;
          break;
      }
    });
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Sort Collection By',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                ...ListSortOption.values.map((opt) {
                  final isSelected = _selectedSort == opt;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: isSelected
                          ? (widget.type == 'ANIME' ? AppColors.brandBlue : const Color(0xFF7C57E8))
                          : context.appTextSecondary,
                      size: 20,
                    ),
                    title: Text(
                      opt.label,
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? (widget.type == 'ANIME' ? AppColors.brandBlue : const Color(0xFF7C57E8))
                            : context.appTextPrimary,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedSort = opt);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showScoreDialog(BuildContext context, Map<String, dynamic> entry, String scoreFormat) {
    final media = entry['media'] as Map<String, dynamic>;
    final title = TextUtil.getPreferredTitle(media['title']);
    final currentScore = (entry['score'] as num?)?.toDouble() ?? 0.0;
    double tempScore = currentScore;

    final is10Point = scoreFormat == 'POINT_10' || scoreFormat == 'POINT_10_DECIMAL';
    final maxScore = is10Point ? 10.0 : 100.0;
    final divisions = is10Point ? (scoreFormat == 'POINT_10_DECIMAL' ? 100 : 10) : 100;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.appSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Rate: $title',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Overpass',
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFE5A158), size: 28),
                  const SizedBox(width: 8),
                  Text(
                    tempScore > 0
                        ? (is10Point
                            ? (scoreFormat == 'POINT_10_DECIMAL'
                                ? tempScore.toStringAsFixed(1)
                                : tempScore.round().toString())
                            : '${tempScore.round()}%')
                        : 'Unrated',
                    style: const TextStyle(
                      fontFamily: 'Overpass',
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Slider(
                value: tempScore.clamp(0.0, maxScore),
                min: 0,
                max: maxScore,
                divisions: divisions,
                activeColor: widget.type == 'ANIME' ? AppColors.brandBlue : const Color(0xFF7C57E8),
                inactiveColor: context.appInputSurface,
                onChanged: (val) {
                  setDialogState(() => tempScore = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: context.appTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final provider = widget.type == 'ANIME'
                    ? animeListControllerProvider
                    : mangaListControllerProvider;
                ref.read(provider.notifier).updateScore(
                      entryId: entry['id'] as int,
                      mediaId: media['id'] as int,
                      score: tempScore,
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.type == 'ANIME' ? AppColors.brandBlue : const Color(0xFF7C57E8),
                foregroundColor: widget.type == 'ANIME' ? context.appBackground : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save Score', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isGuest = authState is! Authenticated;

    final isAnime = widget.type == 'ANIME';
    final accentColor = isAnime ? AppColors.brandBlue : const Color(0xFF7C57E8);
    final listTitle = isAnime ? 'Anime List' : 'Manga List';

    if (isGuest) {
      return Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(title: Text(listTitle)),
        body: EmptyView(
          title: 'Sign in to access your list',
          subtitle: 'Keep track of what you are watching, set scores, and update progress.',
          icon: Icons.bookmark_border_rounded,
          action: ElevatedButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign In to AniList'),
          ),
        ),
      );
    }

    final user = authState.user;
    final scoreFormat = user.scoreFormat;
    final provider = isAnime ? animeListControllerProvider : mangaListControllerProvider;
    final listState = ref.watch(provider);

    // Compute entry count per status tab and total
    int totalCount = 0;
    final Map<String, int> statusCounts = {};
    listState.whenData((lists) {
      for (final listGroup in lists) {
        final st = (listGroup['status'] as String?)?.toUpperCase() ?? '';
        final entries = (listGroup['entries'] as List?) ?? [];
        statusCounts[st] = (statusCounts[st] ?? 0) + entries.length;
        totalCount += entries.length;
      }
    });

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        leadingWidth: canPop ? 40 : null,
        titleSpacing: canPop ? 2 : AppSpacing.p16,
        actionsPadding: const EdgeInsets.only(right: 6),
        title: Row(
          children: [
            Flexible(
              child: Text(
                listTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontWeight: FontWeight.w900,
                  fontSize: canPop ? 16 : 17.5,
                  color: context.appTextPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.appBorder),
              ),
              child: Text(
                '$totalCount',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
            ),
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            icon: Icon(_isSearchVisible ? Icons.search_off_rounded : Icons.search_rounded, size: 20),
            tooltip: 'Search list',
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchDebounce?.cancel();
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
            ),
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.casino_rounded, size: 20),
            tooltip: 'Random Pick',
            onPressed: () {
              final lists = listState.valueOrNull ?? const [];
              final activeStatus = _statuses[_selectedTabIndex];
              final candidates = <Map<String, dynamic>>[];
              for (final group in lists) {
                if ((group['status'] as String?)?.toUpperCase() == activeStatus) {
                  final entries = (group['entries'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
                  for (final e in entries) {
                    final m = e['media'] as Map<String, dynamic>?;
                    if (m != null) candidates.add(m);
                  }
                }
              }
              RandomPickSheet.show(
                context,
                mediaList: candidates,
                titlePreference: user.titleLanguage,
                contextTitle: 'Random from ${_getStatusLabel(activeStatus)}',
              );
            },
          ),
          IconButton(
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
            ),
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.sort_rounded, size: 20),
            tooltip: 'Sort by',
            onPressed: () => _showSortMenu(context),
          ),
          IconButton(
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
            ),
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            icon: Icon(_getLayoutIcon(), size: 20),
            tooltip: 'Switch layout',
            onPressed: _cycleLayoutMode,
          ),
        ],
      ),
      body: Column(
        children: [
          // Recessed Search Input (Home Theme)
          if (_isSearchVisible)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: context.appInputSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.appBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(fontSize: 13, color: context.appTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search $listTitle...',
                    hintStyle: TextStyle(color: context.appTextMuted, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: context.appTextSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, size: 16, color: context.appTextSecondary),
                            onPressed: () {
                              _searchDebounce?.cancel();
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
                      if (mounted) setState(() => _searchQuery = val);
                    });
                  },
                ),
              ),
            ),

          // Custom Pill Status Tabs Bar (Scrollable Pill Selector)
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statuses[index];
                final count = statusCounts[status] ?? 0;
                final isSelected = _selectedTabIndex == index;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedTabIndex = index);
                    _tabController.animateTo(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor : context.appSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: isSelected
                                ? (isAnime ? context.appBackground : Colors.white)
                                : context.appTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isAnime
                                    ? Colors.black.withValues(alpha: 0.18)
                                    : Colors.white.withValues(alpha: 0.25))
                                : (context.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? (isAnime ? context.appBackground : Colors.white)
                                  : context.appTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Main List View
          Expanded(
            child: listState.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.p16),
                child: ShimmerMediaGrid(count: 6),
              ),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.read(provider.notifier).loadLists(),
              ),
              data: (lists) {
                return TabBarView(
                  controller: _tabController,
                  children: _statuses.map((status) {
                    final listGroup = lists.firstWhere(
                      (l) => (l['status'] as String?)?.toUpperCase() == status,
                      orElse: () => {'entries': []},
                    );

                    final rawEntries = (listGroup['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                    // 1. Search Filter
                    var entries = rawEntries.where((entry) {
                      if (_searchQuery.isEmpty) return true;
                      final title = TextUtil.getPreferredTitle(entry['media']?['title']);
                      return title.toLowerCase().contains(_searchQuery.toLowerCase());
                    }).toList();

                    // 2. Sorting: By default sorts by updatedAt DESC (most recently updated first)
                    entries.sort((a, b) {
                      switch (_selectedSort) {
                        case ListSortOption.updatedAt:
                          final updatedCmp = (b['updatedAt'] as int? ?? 0).compareTo(a['updatedAt'] as int? ?? 0);
                          if (updatedCmp != 0) return updatedCmp;
                          return (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0);
                        case ListSortOption.score:
                          final scoreCmp = ((b['score'] as num?) ?? 0).compareTo((a['score'] as num?) ?? 0);
                          if (scoreCmp != 0) return scoreCmp;
                          return (b['updatedAt'] as int? ?? 0).compareTo(a['updatedAt'] as int? ?? 0);
                        case ListSortOption.title:
                          final titleA = TextUtil.getPreferredTitle(a['media']?['title']).toLowerCase();
                          final titleB = TextUtil.getPreferredTitle(b['media']?['title']).toLowerCase();
                          return titleA.compareTo(titleB);
                        case ListSortOption.progress:
                          final progCmp = (b['progress'] as int? ?? 0).compareTo(a['progress'] as int? ?? 0);
                          if (progCmp != 0) return progCmp;
                          return (b['updatedAt'] as int? ?? 0).compareTo(a['updatedAt'] as int? ?? 0);
                      }
                    });

                    if (entries.isEmpty) {
                      return EmptyView(
                        title: 'No entries in ${_getStatusLabel(status)}',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'No matches found for "$_searchQuery".'
                            : 'Add items to your list to see them here.',
                        icon: Icons.movie_filter_outlined,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => ref.read(provider.notifier).loadLists(),
                      color: accentColor,
                      backgroundColor: context.appSurface,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        child: KeyedSubtree(
                          key: ValueKey('${_cardMode.name}_$status'),
                          child: _buildLayout(
                            entries,
                            status: status,
                            accentColor: accentColor,
                            scoreFormat: scoreFormat,
                            onIncrementProgress: (entryId, mediaId, currentProgress, maxCount) {
                              HapticFeedback.lightImpact();
                              ref.read(provider.notifier).incrementProgress(
                                    entryId: entryId,
                                    mediaId: mediaId,
                                    currentProgress: currentProgress,
                                    maxEpisodesOrChapters: maxCount,
                                  );
                            },
                            onIncrementVolume: widget.type == 'MANGA'
                                ? (entryId, mediaId, currentVols, maxVols) {
                                    HapticFeedback.lightImpact();
                                    ref.read(provider.notifier).incrementVolume(
                                          entryId: entryId,
                                          mediaId: mediaId,
                                          currentVolumes: currentVols,
                                          maxVolumes: maxVols,
                                        );
                                  }
                                : null,
                            onUpdateScore: (entry) {
                              _showScoreDialog(context, entry, scoreFormat);
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayout(
    List<Map<String, dynamic>> entries, {
    required String status,
    required Color accentColor,
    required String scoreFormat,
    required void Function(int entryId, int mediaId, int currentProgress, int? maxCount)
        onIncrementProgress,
    void Function(int entryId, int mediaId, int currentVols, int? maxVols)?
        onIncrementVolume,
    required void Function(Map<String, dynamic> entry) onUpdateScore,
  }) {
    final isManga = widget.type == 'MANGA';
    switch (_cardMode) {
      case MediaCardMode.grid:
        final isTablet = MediaQuery.sizeOf(context).width >= 600;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 2,
            childAspectRatio: 0.67,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final media = entry['media'] as Map<String, dynamic>;
            final progress = entry['progress'] as int? ?? 0;
            final maxCount = media['episodes'] as int? ?? media['chapters'] as int?;
            final volProgress = entry['progressVolumes'] as int? ?? 0;
            final maxVols = media['volumes'] as int?;

            return MediaCard(
              media: media,
              mode: MediaCardMode.grid,
              accentColor: accentColor,
              listStatus: status,
              userProgress: progress,
              userVolumeProgress: isManga ? volProgress : null,
              userScore: (entry['score'] as num?)?.toDouble(),
              scoreFormat: scoreFormat,
              onTap: () => _navigateToDetail(context, media['id']),
              onUpdateScore: () => onUpdateScore(entry),
              onIncrementProgress: () => onIncrementProgress(
                entry['id'] as int,
                media['id'] as int,
                progress,
                maxCount,
              ),
              onIncrementVolume: onIncrementVolume != null
                  ? () => onIncrementVolume(
                        entry['id'] as int,
                        media['id'] as int,
                        volProgress,
                        maxVols,
                      )
                  : null,
            );
          },
        );

      case MediaCardMode.compact:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final media = entry['media'] as Map<String, dynamic>;
            final progress = entry['progress'] as int? ?? 0;
            final maxCount = media['episodes'] as int? ?? media['chapters'] as int?;
            final volProgress = entry['progressVolumes'] as int? ?? 0;
            final maxVols = media['volumes'] as int?;

            return MediaCard(
              media: media,
              mode: MediaCardMode.compact,
              accentColor: accentColor,
              listStatus: status,
              userProgress: progress,
              userVolumeProgress: isManga ? volProgress : null,
              userScore: (entry['score'] as num?)?.toDouble(),
              scoreFormat: scoreFormat,
              onTap: () => _navigateToDetail(context, media['id']),
              onUpdateScore: () => onUpdateScore(entry),
              onIncrementProgress: () => onIncrementProgress(
                entry['id'] as int,
                media['id'] as int,
                progress,
                maxCount,
              ),
              onIncrementVolume: onIncrementVolume != null
                  ? () => onIncrementVolume(
                        entry['id'] as int,
                        media['id'] as int,
                        volProgress,
                        maxVols,
                      )
                  : null,
            );
          },
        );

      // Model 1: Neo-Card Detailed (Default)
      case MediaCardMode.list:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final media = entry['media'] as Map<String, dynamic>;
            final progress = entry['progress'] as int? ?? 0;
            final maxCount = media['episodes'] as int? ?? media['chapters'] as int?;
            final volProgress = entry['progressVolumes'] as int? ?? 0;
            final maxVols = media['volumes'] as int?;

            return MediaCard(
              media: media,
              mode: MediaCardMode.list,
              accentColor: accentColor,
              listStatus: status,
              userProgress: progress,
              userVolumeProgress: isManga ? volProgress : null,
              userScore: (entry['score'] as num?)?.toDouble(),
              scoreFormat: scoreFormat,
              onTap: () => _navigateToDetail(context, media['id']),
              onUpdateScore: () => onUpdateScore(entry),
              onIncrementProgress: () => onIncrementProgress(
                entry['id'] as int,
                media['id'] as int,
                progress,
                maxCount,
              ),
              onIncrementVolume: onIncrementVolume != null
                  ? () => onIncrementVolume(
                        entry['id'] as int,
                        media['id'] as int,
                        volProgress,
                        maxVols,
                      )
                  : null,
            );
          },
        );
    }
  }

  void _navigateToDetail(BuildContext context, int? mediaId) {
    if (mediaId != null) {
      Navigator.of(context).push(
        AppPageRoute(page: MediaDetailScreen(mediaId: mediaId)),
      );
    }
  }
}
