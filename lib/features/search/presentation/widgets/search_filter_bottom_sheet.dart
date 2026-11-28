import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

enum GenreFilterState { neutral, included, excluded }

class SearchFilterData {
  final Map<String, GenreFilterState> genres;
  final List<String> formats;
  final List<String> statuses;
  final int? seasonYear;
  final String sortBy;

  SearchFilterData({
    Map<String, GenreFilterState>? genres,
    List<String>? formats,
    List<String>? statuses,
    this.seasonYear,
    this.sortBy = 'POPULARITY_DESC',
  })  : genres = genres ?? {},
        formats = formats ?? [],
        statuses = statuses ?? [];

  int get activeFilterCount {
    int count = 0;
    count += genres.values.where((s) => s != GenreFilterState.neutral).length;
    count += formats.length;
    count += statuses.length;
    if (seasonYear != null) count++;
    if (sortBy != 'POPULARITY_DESC') count++;
    return count;
  }

  List<String> get includedGenres => genres.entries
      .where((e) => e.value == GenreFilterState.included)
      .map((e) => e.key)
      .toList();

  List<String> get excludedGenres => genres.entries
      .where((e) => e.value == GenreFilterState.excluded)
      .map((e) => e.key)
      .toList();
}

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchFilterData initialFilter;
  final Function(SearchFilterData filter) onApply;
  final bool includeAdult;

  const SearchFilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
    this.includeAdult = false,
  });

  @override
  State<SearchFilterBottomSheet> createState() => _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late Map<String, GenreFilterState> _genres;
  late List<String> _formats;
  late List<String> _statuses;
  int? _seasonYear;
  late String _sortBy;

  static const List<String> _baseGenres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Ecchi',
    'Fantasy',
    'Horror',
    'Mahou Shoujo',
    'Mecha',
    'Music',
    'Mystery',
    'Psychological',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
  ];

  List<String> get _allGenres =>
      widget.includeAdult ? [..._baseGenres, 'Hentai'] : _baseGenres;

  final List<String> _allFormats = ['TV', 'MOVIE', 'OVA', 'ONA', 'SPECIAL', 'MANGA'];
  final List<String> _allStatuses = ['RELEASING', 'FINISHED', 'NOT_YET_RELEASED', 'CANCELLED'];

  final Map<String, String> _sortOptions = {
    'POPULARITY_DESC': 'Most Popular',
    'SCORE_DESC': 'Highest Rated',
    'TRENDING_DESC': 'Trending Now',
    'START_DATE_DESC': 'Release Date',
    'TITLE_ROMAJI': 'Title (A-Z)',
  };

  @override
  void initState() {
    super.initState();
    _genres = Map.from(widget.initialFilter.genres);
    _formats = List.from(widget.initialFilter.formats);
    _statuses = List.from(widget.initialFilter.statuses);
    _seasonYear = widget.initialFilter.seasonYear;
    _sortBy = widget.initialFilter.sortBy;
  }

  void _cycleGenre(String genre) {
    setState(() {
      final current = _genres[genre] ?? GenreFilterState.neutral;
      if (current == GenreFilterState.neutral) {
        _genres[genre] = GenreFilterState.included;
      } else if (current == GenreFilterState.included) {
        _genres[genre] = GenreFilterState.excluded;
      } else {
        _genres.remove(genre);
      }
    });
  }

  void _reset() {
    setState(() {
      _genres.clear();
      _formats.clear();
      _statuses.clear();
      _seasonYear = null;
      _sortBy = 'POPULARITY_DESC';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.r24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.appBorder,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
          ),
          const SizedBox(height: 16),
          // Title Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter & Sort', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              TextButton(
                onPressed: _reset,
                child: const Text('Reset', style: TextStyle(color: AppColors.statusDropped, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const Divider(height: 16),

          // Scrollable Filter Sections
          Expanded(
            child: ListView(
              children: [
                // 1. Sort Option
                Text('Sort By', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.appTextSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.appCard,
                    borderRadius: AppSpacing.borderRadius8,
                    border: Border.all(color: context.appBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      dropdownColor: context.appSurface,
                      isExpanded: true,
                      items: _sortOptions.entries.map((e) {
                        return DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Genres with 3-state chips (Neutral, Include, Exclude)
                Row(
                  children: [
                    Text('Genres', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.appTextSecondary)),
                    const Spacer(),
                    Text(
                      'Tap: Include ✓ / Exclude ✕',
                      style: TextStyle(fontSize: 11, color: context.appTextMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _allGenres.map((genre) {
                    final state = _genres[genre] ?? GenreFilterState.neutral;
                    final accent = context.appAccent;
                    Color bgColor = context.appCard;
                    Color borderColor = context.appBorder;
                    Color textColor = context.appTextSecondary;
                    IconData? icon;

                    if (state == GenreFilterState.included) {
                      bgColor = accent.withValues(alpha: 0.2);
                      borderColor = accent;
                      textColor = accent;
                      icon = Icons.check_rounded;
                    } else if (state == GenreFilterState.excluded) {
                      bgColor = AppColors.statusDropped.withValues(alpha: 0.2);
                      borderColor = AppColors.statusDropped;
                      textColor = AppColors.statusDropped;
                      icon = Icons.close_rounded;
                    }

                    return InkWell(
                      onTap: () => _cycleGenre(genre),
                      borderRadius: AppSpacing.borderRadius8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: AppSpacing.borderRadius8,
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, size: 14, color: textColor),
                              const SizedBox(width: 4),
                            ],
                            Text(genre, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: textColor)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 3. Format Multi-select
                Text('Format', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.appTextSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allFormats.map((format) {
                    final isSelected = _formats.contains(format);
                    final accent = context.appAccent;
                    final fg = accent.computeLuminance() > 0.55 ? Colors.black : Colors.white;
                    return FilterChip(
                      label: Text(format.replaceAll('_', ' ')),
                      selected: isSelected,
                      selectedColor: accent,
                      checkmarkColor: fg,
                      labelStyle: TextStyle(
                        color: isSelected ? fg : context.appTextSecondary,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _formats.add(format);
                          } else {
                            _formats.remove(format);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 4. Status Multi-select
                Text('Airing Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.appTextSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allStatuses.map((status) {
                    final isSelected = _statuses.contains(status);
                    final accent = context.appAccent;
                    final fg = accent.computeLuminance() > 0.55 ? Colors.black : Colors.white;
                    return FilterChip(
                      label: Text(status.replaceAll('_', ' ')),
                      selected: isSelected,
                      selectedColor: accent,
                      checkmarkColor: fg,
                      labelStyle: TextStyle(
                        color: isSelected ? fg : context.appTextSecondary,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _statuses.add(status);
                          } else {
                            _statuses.remove(status);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(
                  SearchFilterData(
                    genres: _genres,
                    formats: _formats,
                    statuses: _statuses,
                    seasonYear: _seasonYear,
                    sortBy: _sortBy,
                  ),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appAccent,
                foregroundColor: context.appAccent.computeLuminance() > 0.55
                    ? Colors.black
                    : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadius12),
              ),
              child: const Text('Apply Filters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
