import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/cards/media_card.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/image/app_avatar.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../character_staff/presentation/character_detail_screen.dart';
import '../../character_staff/presentation/staff_detail_screen.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../../seasonal/presentation/seasonal_screen.dart';
import '../data/search_repository.dart';

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

  String _searchQuery = '';
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasNextPage = true;

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
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        if (!_isLoading && _hasNextPage) {
          _currentPage++;
          _performSearch();
        }
      }
    });
    _performSearch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = query);
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
      });
    }

    final repo = ref.read(searchRepositoryProvider);
    final activeTab = _tabs[_tabController.index];

    try {
      Map<String, dynamic> pageData;
      if (activeTab == 'Anime') {
        pageData = await repo.searchMedia(page: _currentPage, search: _searchQuery, type: 'ANIME');
      } else if (activeTab == 'Manga') {
        pageData = await repo.searchMedia(page: _currentPage, search: _searchQuery, type: 'MANGA');
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.p16,
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: AppSpacing.borderRadius12,
            border: Border.all(color: AppColors.darkBorder),
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
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Airing Calendar',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.wb_sunny_rounded),
            tooltip: 'Seasonal Chart',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SeasonalScreen()),
              );
            },
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
      body: _isLoading && _results.isEmpty
          ? const ShimmerMediaGrid(count: 9)
          : RefreshIndicator(
              onRefresh: () => _performSearch(reset: true),
              color: AppColors.brandBlue,
              backgroundColor: AppColors.darkCard,
              child: _buildResults(),
            ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(color: AppColors.darkTextSecondary),
        ),
      );
    }

    final activeTab = _tabs[_tabController.index];

    if (activeTab == 'Anime' || activeTab == 'Manga') {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.p16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.58,
          crossAxisSpacing: AppSpacing.p12,
          mainAxisSpacing: AppSpacing.p16,
        ),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final media = _results[index];
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

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.p16),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _results[index];
        final name = item['name']?['userPreferred'] ?? item['name']?['full'] ?? 'Unknown';
        final image = item['image']?['medium'] as String?;
        final occupations = (item['primaryOccupations'] as List?)?.join(', ');

        return InkWell(
          onTap: () {
            final id = item['id'] as int?;
            if (id != null) {
              if (activeTab == 'Characters') {
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
    );
  }
}
