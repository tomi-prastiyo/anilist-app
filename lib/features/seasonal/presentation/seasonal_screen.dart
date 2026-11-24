import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/cards/media_card.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../home/data/home_repository.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../data/seasonal_repository.dart';

class SeasonalScreen extends ConsumerStatefulWidget {
  const SeasonalScreen({super.key});

  @override
  ConsumerState<SeasonalScreen> createState() => _SeasonalScreenState();
}

class _SeasonalScreenState extends ConsumerState<SeasonalScreen> {
  final ScrollController _scrollController = ScrollController();
  late String _selectedSeason;
  late int _selectedYear;
  List<Map<String, dynamic>> _mediaList = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNextPage = true;

  final List<String> _seasons = ['WINTER', 'SPRING', 'SUMMER', 'FALL'];
  late final List<int> _years;

  @override
  void initState() {
    super.initState();
    _selectedSeason = HomeRepository.getCurrentSeason();
    _selectedYear = HomeRepository.getCurrentYear();

    final currentYear = _selectedYear;
    _years = List.generate(10, (i) => currentYear + 1 - i);

    _scrollController.addListener(_onScroll);
    _loadSeasonalMedia(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger load more at 80% scroll depth with strict sentinel guard
    if (maxScroll > 0 && currentScroll >= maxScroll * 0.8) {
      if (!_isLoading && !_isLoadingMore && _hasNextPage) {
        _loadSeasonalMedia(reset: false);
      }
    }
  }

  Future<void> _loadSeasonalMedia({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _hasNextPage = true;
        _isLoading = true;
        _isLoadingMore = false;
        _mediaList = [];
      });
    } else {
      if (_isLoading || _isLoadingMore || !_hasNextPage) return;
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
    }

    try {
      final repo = ref.read(seasonalRepositoryProvider);
      final data = await repo.fetchSeasonalAnime(
        page: _currentPage,
        season: _selectedSeason,
        year: _selectedYear,
      );

      final pageInfo = data['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      final media = (data['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (mounted) {
        setState(() {
          _hasNextPage = hasNext;
          if (reset) {
            _mediaList = media;
          } else {
            _mediaList.addAll(media);
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        titleSpacing: AppSpacing.p16,
        title: Row(
          children: [
            Text(
              'Seasonal Chart',
              style: TextStyle(
                fontFamily: 'Overpass',
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appBorder),
              ),
              child: Text(
                '$_selectedSeason $_selectedYear',
                style: const TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: 8),
            child: Row(
              children: [
                // Season Selector
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: context.appInputSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSeason,
                        dropdownColor: context.appSurface,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down_rounded, color: context.appTextSecondary),
                        items: _seasons.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: TextStyle(
                                fontFamily: 'Overpass',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSeason = val);
                            if (_scrollController.hasClients) {
                              _scrollController.jumpTo(0);
                            }
                            _loadSeasonalMedia(reset: true);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Year Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.appInputSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      dropdownColor: context.appSurface,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: context.appTextSecondary),
                      items: _years.map((y) {
                        return DropdownMenuItem(
                          value: y,
                          child: Text(
                            '$y',
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.appTextPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedYear = val);
                          if (_scrollController.hasClients) {
                            _scrollController.jumpTo(0);
                          }
                          _loadSeasonalMedia(reset: true);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const ShimmerMediaGrid(count: 9)
          : _mediaList.isEmpty
              ? const EmptyView(
                  title: 'No Anime Found',
                  subtitle: 'No seasonal anime found for this season and year.',
                  icon: Icons.movie_filter_outlined,
                )
              : RefreshIndicator(
                  onRefresh: () => _loadSeasonalMedia(reset: true),
                  color: AppColors.brandBlue,
                  backgroundColor: context.appSurface,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(AppSpacing.p16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final media = _mediaList[index];
                              return MediaCard(
                                media: media,
                                mode: MediaCardMode.grid,
                                onTap: () {
                                  final id = media['id'] as int?;
                                  if (id != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => MediaDetailScreen(mediaId: id),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                            childCount: _mediaList.length,
                          ),
                        ),
                      ),
                      if (_isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandBlue),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 60),
                      ),
                    ],
                  ),
                ),
    );
  }
}
