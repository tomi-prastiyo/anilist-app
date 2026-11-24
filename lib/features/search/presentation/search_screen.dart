import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../shared/cards/media_card.dart';
import '../../../shared/image/app_avatar.dart';
import '../../../shared/list/sliver_paginated_view.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../character_staff/presentation/character_detail_screen.dart';
import '../../character_staff/presentation/staff_detail_screen.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
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
  Timer? _debounceTimer;

  String _searchQuery = '';
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasNextPage = true;
  String? _errorMessage;

  SearchFilterData _filterData = SearchFilterData();
  final List<String> _tabs = ['Anime', 'Manga', 'Characters', 'Staff'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _performSearch(reset: true);
      }
    });
    _performSearch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      setState(() => _searchQuery = query);
      if (query.trim().isNotEmpty) {
        ref.read(localStorageServiceProvider).addRecentSearch(query.trim());
      }
      _performSearch(reset: true);
    });
  }

  Future<void> _performSearch({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _hasNextPage = true;
        _results.clear();
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final repo = ref.read(searchRepositoryProvider);
    final activeTab = _tabs[_tabController.index];

    try {
      Map<String, dynamic> pageData;
      if (activeTab == 'Anime' || activeTab == 'Manga') {
        pageData = await repo.searchMedia(
          page: _currentPage,
          search: _searchQuery,
          type: activeTab == 'Anime' ? 'ANIME' : 'MANGA',
          genreIn: _filterData.includedGenres,
          genreNotIn: _filterData.excludedGenres,
          formatIn: _filterData.formats,
          statusIn: _filterData.statuses,
          seasonYear: _filterData.seasonYear,
          sortBy: _filterData.sortBy,
        );
      } else if (activeTab == 'Characters') {
        pageData = await repo.searchCharacters(page: _currentPage, search: _searchQuery);
      } else {
        pageData = await repo.searchStaff(page: _currentPage, search: _searchQuery);
      }

      final pageInfo = pageData['pageInfo'] as Map<String, dynamic>?;
      _hasNextPage = pageInfo?['hasNextPage'] as bool? ?? false;

      List<Map<String, dynamic>> newItems = [];
      if (activeTab == 'Anime' || activeTab == 'Manga') {
        newItems = (pageData['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      } else if (activeTab == 'Characters') {
        newItems = (pageData['characters'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      } else {
        newItems = (pageData['staff'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      }

      if (mounted) {
        setState(() {
          if (reset) {
            _results = newItems;
          } else {
            _results.addAll(newItems);
          }
          _isLoading = false;
        });
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

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterBottomSheet(
        initialFilter: _filterData,
        onApply: (newFilter) {
          setState(() => _filterData = newFilter);
          _performSearch(reset: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(localStorageServiceProvider);
    final recentSearches = storage.getRecentSearches();
    final filterCount = _filterData.activeFilterCount;
    final isMediaTab = _tabController.index == 0 || _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.p16,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceInput,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search AniList...',
              hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.darkTextSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          if (isMediaTab)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Filter & Sort',
                  onPressed: _openFilterModal,
                ),
                if (filterCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.brandBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$filterCount',
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Airing Calendar',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CalendarScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.wb_sunny_rounded),
            tooltip: 'Seasonal Chart',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SeasonalScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brandBlue,
          labelColor: AppColors.brandBlue,
          unselectedLabelColor: AppColors.darkTextSecondary,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Recent Searches bar if query is empty
          if (_searchQuery.isEmpty && recentSearches.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: 8),
              color: AppColors.darkSurface,
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 16, color: AppColors.darkTextMuted),
                  const SizedBox(width: 8),
                  const Text('Recent: ', style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: recentSearches.map((query) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(query, style: const TextStyle(fontSize: 11)),
                              backgroundColor: AppColors.darkCard,
                              side: const BorderSide(color: AppColors.darkBorder),
                              onPressed: () {
                                _searchController.text = query;
                                _onSearchChanged(query);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_all_rounded, size: 18, color: AppColors.darkTextMuted),
                    tooltip: 'Clear History',
                    onPressed: () async {
                      await storage.clearRecentSearches();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],

          // Results View
          Expanded(
            child: SliverPaginatedView<Map<String, dynamic>>(
              items: _results,
              isLoading: _isLoading,
              hasNextPage: _hasNextPage,
              errorMessage: _errorMessage,
              isGrid: isMediaTab,
              onRefresh: () => _performSearch(reset: true),
              onLoadMore: () {
                _currentPage++;
                _performSearch();
              },
              itemBuilder: (context, item, index) {
                if (isMediaTab) {
                  return MediaCard(
                    media: item,
                    mode: MediaCardMode.grid,
                    onTap: () {
                      final id = item['id'] as int?;
                      if (id != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => MediaDetailScreen(mediaId: id)),
                        );
                      }
                    },
                  );
                }

                // Characters or Staff List Tile
                final name = item['name']?['userPreferred'] ?? item['name']?['full'] ?? 'Unknown';
                final image = item['image']?['medium'] as String?;
                final occupations = (item['primaryOccupations'] as List?)?.join(', ');

                return InkWell(
                  onTap: () {
                    final id = item['id'] as int?;
                    if (id != null) {
                      if (_tabController.index == 2) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => CharacterDetailScreen(characterId: id)),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => StaffDetailScreen(staffId: id)),
                        );
                      }
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
                        AppAvatar(imageUrl: image, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              if (occupations != null) ...[
                                const SizedBox(height: 2),
                                Text(occupations, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
