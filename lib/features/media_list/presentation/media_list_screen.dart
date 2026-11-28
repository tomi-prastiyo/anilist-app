import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/yuyuyu_assets.dart';
import '../../../core/settings/content_settings_provider.dart';
import '../../../core/utils/media_progress_util.dart';
import '../../../core/utils/score_util.dart';
import '../../../core/utils/text_util.dart';
import '../../../shared/cards/media_card.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/widgets/random_pick_sheet.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../seasonal/presentation/seasonal_screen.dart';
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

  Color _resolveAccentColor(BuildContext context) {
    final isAnime = widget.type == 'ANIME';
    return context.isYuYuYu
        ? (isAnime ? context.appAccent : YuYuYuAssets.shinjuGold)
        : (isAnime ? AppColors.brandBlue : const Color(0xFF7C57E8));
  }

  void _showSortMenu(BuildContext context) {
    final accentColor = _resolveAccentColor(context);
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
                      color: isSelected ? accentColor : context.appTextSecondary,
                      size: 20,
                    ),
                    title: Text(
                      opt.label,
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? accentColor : context.appTextPrimary,
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

  String _getLayoutLabel() {
    switch (_cardMode) {
      case MediaCardMode.list:
        return 'List';
      case MediaCardMode.compact:
        return 'Compact';
      case MediaCardMode.grid:
        return 'Grid';
    }
  }

  double _maxScoreForFormat(String format) {
    switch (format) {
      case 'POINT_10_DECIMAL':
      case 'POINT_10':
        return 10.0;
      case 'POINT_5':
        return 5.0;
      case 'POINT_3':
        return 3.0;
      case 'POINT_100':
      default:
        return 100.0;
    }
  }

  double _stepForFormat(String format) =>
      format == 'POINT_10_DECIMAL' ? 0.5 : 1.0;

  double _normalizedScoreValue(String format, double raw) {
    final max = _maxScoreForFormat(format);
    if (raw <= max) return raw;
    return ((raw / 100.0) * max).clamp(0.0, max);
  }

  void _showScoreDialog(BuildContext context, Map<String, dynamic> entry, String scoreFormat) {
    final media = entry['media'] as Map<String, dynamic>;
    final titleLang = ref.read(titleLanguageProvider);
    final title = TextUtil.getPreferredTitle(media['title'], preference: titleLang);
    final accentColor = _resolveAccentColor(context);
    final maxScore = _maxScoreForFormat(scoreFormat);
    final step = _stepForFormat(scoreFormat);
    double tempScore = _normalizedScoreValue(
      scoreFormat,
      (entry['score'] as num?)?.toDouble() ?? 0.0,
    );

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
            style: TextStyle(
              fontFamily: 'Overpass',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: context.appTextPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: tempScore > 0
                        ? () => setDialogState(
                              () => tempScore = (tempScore - step).clamp(0.0, maxScore),
                            )
                        : null,
                    icon: const Icon(Icons.remove_rounded, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.star_rounded, color: Color(0xFFE5A158), size: 26),
                  const SizedBox(width: 6),
                  Text(
                    tempScore > 0
                        ? ScoreUtil.formatScore(tempScore, format: scoreFormat)
                        : 'Unrated',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: context.appTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: tempScore < maxScore
                        ? () => setDialogState(
                              () => tempScore = (tempScore + step).clamp(0.0, maxScore),
                            )
                        : null,
                    icon: const Icon(Icons.add_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: tempScore.clamp(0.0, maxScore),
                min: 0,
                max: maxScore,
                divisions: (maxScore / step).round(),
                activeColor: accentColor,
                inactiveColor: context.appInputSurface,
                onChanged: (val) {
                  setDialogState(() => tempScore = val);
                },
              ),
            ],
          ),
          actions: [
            if (tempScore > 0)
              TextButton(
                onPressed: () => setDialogState(() => tempScore = 0.0),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: AppColors.statusDropped),
                ),
              ),
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
                backgroundColor: accentColor,
                foregroundColor: accentColor.computeLuminance() > 0.55 ? Colors.black : Colors.white,
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
    final titleLang = ref.watch(titleLanguageProvider);
    final isGuest = authState is! Authenticated;

    final isAnime = widget.type == 'ANIME';
    final accentColor = _resolveAccentColor(context);
    final accentForeground = accentColor.computeLuminance() > 0.55 ? Colors.black : Colors.white;
    final listTitle = isAnime ? 'Anime List' : 'Manga List';

    if (isGuest) {
      return Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(title: Text(listTitle)),
        body: EmptyView(
          title: 'Sign in to access your list',
          subtitle: 'Keep track of what you are watching, set scores, and update progress.',
          icon: Icons.bookmark_border_rounded,
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: accentForeground,
                ),
                child: const Text('Sign In to AniList'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    AppPageRoute(
                      page: isAnime ? const SeasonalScreen() : const SearchScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withValues(alpha: 0.45)),
                ),
                icon: Icon(
                  isAnime ? Icons.auto_awesome_rounded : Icons.explore_rounded,
                  size: 16,
                ),
                label: Text(isAnime ? 'Explore Seasonal Chart' : 'Explore Popular Manga'),
              ),
            ],
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
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
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
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
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
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.sort_rounded, size: 20),
            tooltip: 'Sort by',
            onPressed: () => _showSortMenu(context),
          ),
          IconButton(
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            icon: Icon(_getLayoutIcon(), size: 20),
            tooltip: 'Switch layout',
            onPressed: _cycleLayoutMode,
          ),
        ],
      ),
      body: Column(
        children: [
          // Smooth Search Reveal
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _isSearchVisible
                ? Padding(
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
                          suffixIcon: _searchController.text.isNotEmpty
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
                          setState(() {});
                          _searchDebounce?.cancel();
                          _searchDebounce = Timer(const Duration(milliseconds: 250), () {
                            if (mounted) setState(() => _searchQuery = val);
                          });
                        },
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
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
                                ? (accentColor.computeLuminance() > 0.55
                                    ? Colors.black
                                    : Colors.white)
                                : context.appTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (accentColor.computeLuminance() > 0.55
                                    ? Colors.black.withValues(alpha: 0.16)
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
                                  ? (accentColor.computeLuminance() > 0.55
                                      ? Colors.black
                                      : Colors.white)
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
          // Compact Active Controls Strip (Sort, Layout & Search Indicator)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.p16, 2, AppSpacing.p16, 4),
            child: SizedBox(
              height: 30,
              child: Row(
                children: [
                  _buildControlPill(
                    context,
                    icon: Icons.sort_rounded,
                    label: _selectedSort.label,
                    accentColor: accentColor,
                    onTap: () => _showSortMenu(context),
                  ),
                  const SizedBox(width: 8),
                  _buildControlPill(
                    context,
                    icon: _getLayoutIcon(),
                    label: _getLayoutLabel(),
                    accentColor: accentColor,
                    onTap: _cycleLayoutMode,
                  ),
                  const Spacer(),
                  if (_searchQuery.trim().isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchDebounce?.cancel();
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                '"${_searchQuery.trim()}"',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.close_rounded, size: 12, color: accentColor),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

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
                      final title = TextUtil.getPreferredTitle(
                        entry['media']?['title'],
                        preference: titleLang,
                      );
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
                          final titleA = TextUtil.getPreferredTitle(
                            a['media']?['title'],
                            preference: titleLang,
                          ).toLowerCase();
                          final titleB = TextUtil.getPreferredTitle(
                            b['media']?['title'],
                            preference: titleLang,
                          ).toLowerCase();
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
                            titleLanguage: titleLang,
                            onIncrementProgress:
                                (entryId, mediaId, currentProgress, maxCount, maxVolumes, currentRepeat) {
                              HapticFeedback.lightImpact();
                              ref.read(provider.notifier).incrementProgress(
                                    entryId: entryId,
                                    mediaId: mediaId,
                                    currentProgress: currentProgress,
                                    maxEpisodesOrChapters: maxCount,
                                    maxVolumes: maxVolumes,
                                    currentStatus: status,
                                    currentRepeat: currentRepeat,
                                  );
                              if (maxCount != null && currentProgress + 1 >= maxCount) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      status == 'REPEATING'
                                          ? 'Rewatch/Reread Completed (+1 Repeat, Finish Date set)!'
                                          : 'Marked as Completed (Finish Date set)!',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
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

  Widget _buildControlPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.appBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13.5, color: accentColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayout(
    List<Map<String, dynamic>> entries, {
    required String status,
    required Color accentColor,
    required String scoreFormat,
    required String titleLanguage,
    required void Function(
      int entryId,
      int mediaId,
      int currentProgress,
      int? maxCount,
      int? maxVolumes,
      int currentRepeat,
    ) onIncrementProgress,
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
            final repeatCount = entry['repeat'] as int? ?? 0;
            final canIncProg = MediaProgressUtil.canIncrementProgress(
              status: status,
              progress: progress,
              media: media,
            );
            final canIncVol = onIncrementVolume != null &&
                MediaProgressUtil.canIncrementVolume(
                  status: status,
                  progressVolumes: volProgress,
                  media: media,
                );

            return MediaCard(
              media: media,
              mode: MediaCardMode.grid,
              accentColor: accentColor,
              titlePreference: titleLanguage,
              listStatus: status,
              userProgress: progress,
              userVolumeProgress: isManga ? volProgress : null,
              userScore: (entry['score'] as num?)?.toDouble(),
              scoreFormat: scoreFormat,
              onTap: () => _navigateToDetail(context, media['id']),
              onUpdateScore: () => onUpdateScore(entry),
              onIncrementProgress: canIncProg
                  ? () => onIncrementProgress(
                        entry['id'] as int,
                        media['id'] as int,
                        progress,
                        maxCount,
                        maxVols,
                        repeatCount,
                      )
                  : null,
              onIncrementVolume: canIncVol
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
            final repeatCount = entry['repeat'] as int? ?? 0;
            final canIncProg = MediaProgressUtil.canIncrementProgress(
              status: status,
              progress: progress,
              media: media,
            );
            final canIncVol = onIncrementVolume != null &&
                MediaProgressUtil.canIncrementVolume(
                  status: status,
                  progressVolumes: volProgress,
                  media: media,
                );

            return MediaCard(
              media: media,
              mode: MediaCardMode.compact,
              accentColor: accentColor,
              titlePreference: titleLanguage,
              listStatus: status,
              userProgress: progress,
              userVolumeProgress: isManga ? volProgress : null,
              userScore: (entry['score'] as num?)?.toDouble(),
              scoreFormat: scoreFormat,
              onTap: () => _navigateToDetail(context, media['id']),
              onUpdateScore: () => onUpdateScore(entry),
              onIncrementProgress: canIncProg
                  ? () => onIncrementProgress(
                        entry['id'] as int,
                        media['id'] as int,
                        progress,
                        maxCount,
                        maxVols,
                        repeatCount,
                      )
                  : null,
              onIncrementVolume: canIncVol
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
            final repeatCount = entry['repeat'] as int? ?? 0;
            final canIncProg = MediaProgressUtil.canIncrementProgress(
              status: status,
              progress: progress,
              media: media,
            );
            final canIncVol = onIncrementVolume != null &&
                MediaProgressUtil.canIncrementVolume(
                  status: status,
                  progressVolumes: volProgress,
                  media: media,
                );

            return MediaCard(
              media: media,
              mode: MediaCardMode.list,
              accentColor: accentColor,
              titlePreference: titleLanguage,
              listStatus: status,
              userProgress: progress,
              userVolumeProgress: isManga ? volProgress : null,
              userScore: (entry['score'] as num?)?.toDouble(),
              scoreFormat: scoreFormat,
              onTap: () => _navigateToDetail(context, media['id']),
              onUpdateScore: () => onUpdateScore(entry),
              onIncrementProgress: canIncProg
                  ? () => onIncrementProgress(
                        entry['id'] as int,
                        media['id'] as int,
                        progress,
                        maxCount,
                        maxVols,
                        repeatCount,
                      )
                  : null,
              onIncrementVolume: canIncVol
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
