import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/cards/media_card.dart';
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
  late String _selectedSeason;
  late int _selectedYear;
  List<Map<String, dynamic>> _mediaList = [];
  bool _isLoading = true;

  final List<String> _seasons = ['WINTER', 'SPRING', 'SUMMER', 'FALL'];
  late final List<int> _years;

  @override
  void initState() {
    super.initState();
    _selectedSeason = HomeRepository.getCurrentSeason();
    _selectedYear = HomeRepository.getCurrentYear();

    final currentYear = _selectedYear;
    _years = List.generate(10, (i) => currentYear + 1 - i);

    _loadSeasonalMedia();
  }

  Future<void> _loadSeasonalMedia() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(seasonalRepositoryProvider);
      final data = await repo.fetchSeasonalAnime(
        page: 1,
        season: _selectedSeason,
        year: _selectedYear,
      );
      final media = (data['media'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) {
        setState(() {
          _mediaList = media;
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
        title: const Text('Seasonal Chart'),
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
                      color: AppColors.darkCard,
                      borderRadius: AppSpacing.borderRadius8,
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSeason,
                        dropdownColor: AppColors.darkSurface,
                        isExpanded: true,
                        items: _seasons.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSeason = val);
                            _loadSeasonalMedia();
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
                    color: AppColors.darkCard,
                    borderRadius: AppSpacing.borderRadius8,
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      dropdownColor: AppColors.darkSurface,
                      items: _years.map((y) {
                        return DropdownMenuItem(
                          value: y,
                          child: Text('$y', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedYear = val);
                          _loadSeasonalMedia();
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
          : RefreshIndicator(
              onRefresh: _loadSeasonalMedia,
              color: AppColors.brandBlue,
              backgroundColor: AppColors.darkCard,
              child: GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.p16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: AppSpacing.p12,
                  mainAxisSpacing: AppSpacing.p16,
                ),
                itemCount: _mediaList.length,
                itemBuilder: (context, index) {
                  final media = _mediaList[index];
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
              ),
            ),
    );
  }
}
