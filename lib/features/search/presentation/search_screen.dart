import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/utils/text_util.dart';
import '../../../shared/cards/media_card.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/image/app_network_image.dart';
import '../../../shared/widgets/random_pick_sheet.dart';
import '../../character_staff/presentation/character_detail_screen.dart';
import '../../character_staff/presentation/staff_detail_screen.dart';
import '../../home/presentation/airing_schedule_screen.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../../media_list/presentation/media_list_controller.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../seasonal/presentation/seasonal_screen.dart';
import '../data/search_repository.dart';
import 'widgets/search_filter_bottom_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  int _selectedTabIndex = 0;
  String _searchQuery = '';
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNextPage = true;
  String? _errorMessage;

  // Search Sequence ID to discard out-of-order race responses
  int _searchSequence = 0;

  // In-memory LRU cache for 0ms instantaneous tab switching and repeat queries
  final Map<String, List<Map<String, dynamic>>> _searchCache = {};
  final Map<String, bool> _hasNextPageCache = {};

  // Layout mode switcher: Grid (Poster) vs List (Neo-Card Detailed)
  MediaCardMode _layoutMode = MediaCardMode.grid;

  SearchFilterData _filterData = SearchFilterData();
  final List<String> _tabs = ['Anime', 'Manga', 'Characters', 'Staff', 'Users'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _selectedTabIndex != _tabController.index) {
        setState(() => _selectedTabIndex = _tabController.index);
        _performSearch(reset: true);
      }
    });

    _scrollController.addListener(_onScroll);
    _performSearch(reset: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger load more at 80% scroll depth with strict sentinel guard
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.8) {
      if (!_isLoading && !_isLoadingMore && _hasNextPage) {
        _performSearch(reset: false);
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_searchQuery != query) {
        setState(() => _searchQuery = query);
        if (query.trim().isNotEmpty) {
          ref.read(localStorageServiceProvider).addRecentSearch(query.trim());
        }
        _performSearch(reset: true);
      }
    });
  }

  String _buildCacheKey(String tab, int page) {
    return '$tab::${_searchQuery.trim()}::${_filterData.includedGenres.join(',')}:${_filterData.excludedGenres.join(',')}:${_filterData.formats.join(',')}:${_filterData.statuses.join(',')}:${_filterData.seasonYear}:${_filterData.sortBy}::$page';
  }

  Future<void> _performSearch({bool reset = false}) async {
    final activeTab = _tabs[_selectedTabIndex];

    if (reset) {
      final cacheKey = _buildCacheKey(activeTab, 1);
      if (_searchCache.containsKey(cacheKey) && _searchCache[cacheKey]!.isNotEmpty) {
        // Instant 0ms cache emission with fresh list copy
        setState(() {
          _currentPage = 1;
          _hasNextPage = _hasNextPageCache[cacheKey] ?? false;
          _results = List<Map<String, dynamic>>.from(_searchCache[cacheKey]!);
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
        return;
      }

      setState(() {
        _currentPage = 1;
        _hasNextPage = true;
        _results = [];
        _isLoading = true;
        _isLoadingMore = false;
        _errorMessage = null;
      });
    } else {
      if (_isLoading || _isLoadingMore || !_hasNextPage) return;
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
    }

    final sequence = ++_searchSequence;
    final targetPage = _currentPage;
    final repo = ref.read(searchRepositoryProvider);

    try {
      Map<String, dynamic> pageData;
      if (activeTab == 'Anime' || activeTab == 'Manga') {
        pageData = await repo.searchMedia(
          page: targetPage,
          search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
          type: activeTab == 'Anime' ? 'ANIME' : 'MANGA',
          genreIn: _filterData.includedGenres.isEmpty ? null : _filterData.includedGenres,
          genreNotIn: _filterData.excludedGenres.isEmpty ? null : _filterData.excludedGenres,
          formatIn: _filterData.formats.isEmpty ? null : _filterData.formats,
          statusIn: _filterData.statuses.isEmpty ? null : _filterData.statuses,
          seasonYear: _filterData.seasonYear,
          sortBy: _filterData.sortBy,
        );
      } else if (activeTab == 'Characters') {
        pageData = await repo.searchCharacters(
          page: targetPage,
          search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        );
      } else if (activeTab == 'Staff') {
        pageData = await repo.searchStaff(
          page: targetPage,
          search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        );
      } else {
        pageData = await repo.searchUsers(
          page: targetPage,
          search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        );
      }

      // If a newer search started while this was in-flight, discard this result
      if (!mounted || sequence != _searchSequence) return;

      final pageInfo = pageData['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;

      List<Map<String, dynamic>> newItems = [];
      if (activeTab == 'Anime' || activeTab == 'Manga') {
        newItems = (pageData['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      } else if (activeTab == 'Characters') {
        newItems = (pageData['characters'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      } else if (activeTab == 'Staff') {
        newItems = (pageData['staff'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      } else {
        newItems = (pageData['users'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      }

      // Cache page 1 for instant back-navigation with deep list copy
      if (reset) {
        final cacheKey = _buildCacheKey(activeTab, 1);
        _searchCache[cacheKey] = List<Map<String, dynamic>>.from(newItems);
        _hasNextPageCache[cacheKey] = hasNext;
      }

      setState(() {
        _hasNextPage = hasNext;
        if (reset) {
          _results = List<Map<String, dynamic>>.from(newItems);
        } else {
          _results.addAll(newItems);
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || sequence != _searchSequence) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterBottomSheet(
        initialFilter: _filterData,
        onApply: (newFilter) {
          _searchCache.clear();
          _hasNextPageCache.clear();
          setState(() => _filterData = newFilter);
          _performSearch(reset: true);
        },
      ),
    );
  }

  void _toggleLayoutMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _layoutMode = _layoutMode == MediaCardMode.grid
          ? MediaCardMode.list
          : MediaCardMode.grid;
    });
  }

  Color _getTabAccentColor(int index) {
    switch (index) {
      case 0:
        return AppColors.brandBlue; // Anime: Cyan
      case 1:
        return const Color(0xFF7C57E8); // Manga: Purple
      case 2:
        return const Color(0xFFE5A158); // Characters: Gold
      case 3:
        return const Color(0xFF46C07B); // Staff: Green
      case 4:
      default:
        return const Color(0xFFE84D88); // Users: Pink
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterCount = _filterData.activeFilterCount;
    final isMediaTab = _selectedTabIndex == 0 || _selectedTabIndex == 1;
    final activeAccent = _getTabAccentColor(_selectedTabIndex);

    final listGroups = (_selectedTabIndex == 0
            ? ref.watch(animeListControllerProvider).valueOrNull
            : (_selectedTabIndex == 1 ? ref.watch(mangaListControllerProvider).valueOrNull : null)) ??
        const [];
    final inListMap = <int, String>{};
    for (final group in listGroups) {
      final st = (group['status'] as String?) ?? '';
      final entries = (group['entries'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final e in entries) {
        final mid = e['media']?['id'] as int?;
        if (mid != null && st.isNotEmpty) {
          inListMap[mid] = st;
        }
      }
    }

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        titleSpacing: AppSpacing.p16,
        actionsPadding: const EdgeInsets.only(right: 6),
        title: Text(
          'Search',
          style: TextStyle(
            fontFamily: 'Overpass',
            fontWeight: FontWeight.w900,
            fontSize: 19,
            color: context.appTextPrimary,
          ),
        ),
        actions: [
          // 1. Airing Schedule
          IconButton(
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
            ),
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.calendar_month_rounded, size: 20),
            tooltip: 'Airing Schedule',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AiringScheduleScreen()),
            ),
          ),
          // 2. Seasonal Chart
          IconButton(
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(34, 34),
              padding: EdgeInsets.zero,
            ),
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            tooltip: 'Seasonal Chart',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SeasonalScreen()),
            ),
          ),
          // 3. Filter & Sort Modal with active badge
          if (isMediaTab)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                  ),
                  constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  tooltip: 'Filter & Sort',
                  onPressed: _openFilterModal,
                ),
                if (filterCount > 0)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        color: activeAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$filterCount',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          // 4. Random Pick from current search/discover results
          if (isMediaTab && _results.isNotEmpty)
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
              onPressed: () => RandomPickSheet.show(
                context,
                mediaList: _results.whereType<Map<String, dynamic>>().toList(),
                titlePreference: ref.read(localStorageServiceProvider).titleLanguage,
                contextTitle: _selectedTabIndex == 0 ? 'Random Anime Pick' : 'Random Manga Pick',
              ),
            ),
          // 5. Layout Mode Toggle (Grid vs Detailed List)
          if (isMediaTab)
            IconButton(
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(34, 34),
                padding: EdgeInsets.zero,
              ),
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              icon: Icon(
                _layoutMode == MediaCardMode.grid
                    ? Icons.view_headline_rounded
                    : Icons.grid_view_rounded,
                size: 20,
              ),
              tooltip: 'Switch layout',
              onPressed: _toggleLayoutMode,
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Recessed Search Input (Home & MediaList Design Language)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: context.appInputSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.appBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(fontSize: 13, color: context.appTextPrimary, fontFamily: 'Overpass'),
                decoration: InputDecoration(
                  hintText: 'Search anime, manga, characters...',
                  hintStyle: TextStyle(color: context.appTextMuted, fontSize: 13, fontFamily: 'Overpass'),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: activeAccent),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, size: 16, color: context.appTextSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // 2. Custom Pill Category Tabs Bar (Scrollable Pill Selector identical to MediaListScreen)
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tabName = _tabs[index];
                final isSelected = _selectedTabIndex == index;
                final tabColor = _getTabAccentColor(index);

                return GestureDetector(
                  onTap: () {
                    if (_selectedTabIndex != index) {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedTabIndex = index);
                      _tabController.animateTo(index);
                      _performSearch(reset: true);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? tabColor : context.appSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? tabColor : context.appBorder,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: tabColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      tabName,
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : context.appTextSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Results Section (Directly into clean Grid or List, NO cluttered ribbons!)
          Expanded(
            child: _buildResultsView(isMediaTab, activeAccent, inListMap),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(bool isMediaTab, Color activeAccent, Map<int, String> inListMap) {
    if (_errorMessage != null && _results.isEmpty) {
      return ErrorView(
        message: _errorMessage!,
        onRetry: () => _performSearch(reset: true),
      );
    }

    if (_isLoading && _results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.p16),
        child: ShimmerMediaGrid(count: 6),
      );
    }

    final bool isEmptyQuery = _searchQuery.trim().isEmpty;

    if (_results.isEmpty) {
      return EmptyView(
        title: !isEmptyQuery
            ? 'No matches found for "$_searchQuery"'
            : 'Explore AniList',
        subtitle: !isEmptyQuery
            ? 'Try searching with different keywords or clearing filters.'
            : 'Type titles, characters, or staff above to search.',
        icon: Icons.search_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _searchCache.clear();
        _hasNextPageCache.clear();
        await _performSearch(reset: true);
      },
      color: activeAccent,
      backgroundColor: context.appSurface,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Results List / Grid
          if (isMediaTab)
            _layoutMode == MediaCardMode.grid
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
                      childAspectRatio: 0.67,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final id = item['id'] as int?;
                      return MediaCard(
                        media: item,
                        mode: MediaCardMode.grid,
                        accentColor: activeAccent,
                        inListBadge: id != null ? inListMap[id] : null,
                        onTap: () {
                          if (id != null) {
                            Navigator.of(context).push(
                              AppPageRoute(page: MediaDetailScreen(mediaId: id)),
                            );
                          }
                        },
                      ).animateEntrance(index: index);
                    },
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _results.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final id = item['id'] as int?;
                      return MediaCard(
                        media: item,
                        mode: MediaCardMode.list,
                        accentColor: activeAccent,
                        inListBadge: id != null ? inListMap[id] : null,
                        onTap: () {
                          if (id != null) {
                            Navigator.of(context).push(
                              AppPageRoute(page: MediaDetailScreen(mediaId: id)),
                            );
                          }
                        },
                      ).animateEntrance(index: index);
                    },
                  )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _results[index];

                // 1. Users Tab
                if (_selectedTabIndex == 4) {
                  final name = item['name'] as String? ?? 'Unknown';
                  final avatar = item['avatar']?['medium'] as String? ?? item['avatar']?['large'] as String?;
                  final cleanAbout = TextUtil.cleanBioSnippet(item['about'] as String?);

                  return InkWell(
                    onTap: () {
                      final id = item['id'] as int?;
                      if (id != null) {
                        Navigator.of(context).push(
                          AppPageRoute(page: ProfileScreen(userId: id, userName: name)),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.appBorder),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: AppNetworkImage(
                              imageUrl: avatar,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontFamily: 'Overpass',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: context.appTextPrimary,
                                  ),
                                ),
                                if (cleanAbout != null && cleanAbout.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    cleanAbout,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Overpass',
                                      color: context.appTextSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, size: 20, color: context.appTextMuted),
                        ],
                      ),
                    ),
                  );
                }

                // 2. Characters & Staff Tabs
                final name = item['name']?['userPreferred'] ?? item['name']?['full'] ?? 'Unknown';
                final nativeName = item['name']?['native'] as String?;
                final image = (item['image']?['large'] ?? item['image']?['medium']) as String?;
                final occupations = (item['primaryOccupations'] as List?)?.join(', ');

                return InkWell(
                  onTap: () {
                    final id = item['id'] as int?;
                    if (id != null) {
                      if (_selectedTabIndex == 2) {
                        Navigator.of(context).push(
                          AppPageRoute(page: CharacterDetailScreen(characterId: id)),
                        );
                      } else {
                        Navigator.of(context).push(
                          AppPageRoute(page: StaffDetailScreen(staffId: id)),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AppNetworkImage(
                            imageUrl: image,
                            width: 52,
                            height: 68,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontFamily: 'Overpass',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: context.appTextPrimary,
                                ),
                              ),
                              if (nativeName != null && nativeName.isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(
                                  nativeName,
                                  style: TextStyle(
                                    fontFamily: 'Overpass',
                                    color: context.appTextMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                              if (occupations != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  occupations,
                                  style: TextStyle(
                                    fontFamily: 'Overpass',
                                    color: context.appTextSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 20, color: context.appTextMuted),
                      ],
                    ),
                  ),
                ).animateEntrance(index: index);
              },
            ),

          // Pagination Loading Spinner at the bottom
          if (_isLoadingMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(activeAccent),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
