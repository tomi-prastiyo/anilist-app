import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/text_util.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/image/app_network_image.dart';
import '../../../shared/widgets/tactile_scale.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../../media_list/presentation/media_list_controller.dart';
import '../data/home_repository.dart';

class AiringScheduleScreen extends ConsumerStatefulWidget {
  const AiringScheduleScreen({super.key});

  @override
  ConsumerState<AiringScheduleScreen> createState() => _AiringScheduleScreenState();
}

class _AiringScheduleScreenState extends ConsumerState<AiringScheduleScreen> {
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  bool _onlyMyList = true;
  List<Map<String, dynamic>> _schedules = [];

  // 7 days starting from today
  late final List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _days = List.generate(7, (index) => DateTime(now.year, now.month, now.day).add(Duration(days: index)));
    _loadScheduleForDay(0);
  }

  List<int> _collectMyMediaIds() {
    final animeLists = ref.read(animeListControllerProvider).valueOrNull ?? const [];
    final ids = <int>{};
    for (final group in animeLists) {
      final entries = (group['entries'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final e in entries) {
        final mid = e['media']?['id'] as int?;
        if (mid != null) ids.add(mid);
      }
    }
    return ids.toList();
  }

  Future<void> _loadScheduleForDay(int dayIndex) async {
    setState(() {
      _selectedDayIndex = dayIndex;
      _isLoading = true;
    });

    final targetDate = _days[dayIndex];
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day).millisecondsSinceEpoch ~/ 1000;
    final endOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59).millisecondsSinceEpoch ~/ 1000;
    final myIds = _onlyMyList ? _collectMyMediaIds() : null;

    if (_onlyMyList && (myIds == null || myIds.isEmpty)) {
      if (mounted) {
        setState(() {
          _schedules = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final repo = ref.read(homeRepositoryProvider);
      final list = await repo.fetchAiringSchedule(
        airingAtGreater: startOfDay,
        airingAtLesser: endOfDay,
        mediaIds: myIds,
      );
      if (mounted) {
        setState(() {
          _schedules = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getDayTitle(int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    return DateFormat('EEE').format(_days[index]);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _days[_selectedDayIndex];
    final accent = context.appAccent;
    final animeLists = ref.watch(animeListControllerProvider).valueOrNull ?? const [];
    final myMediaIds = <int>{};
    for (final group in animeLists) {
      final entries = (group['entries'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      for (final e in entries) {
        final mid = e['media']?['id'] as int?;
        if (mid != null) myMediaIds.add(mid);
      }
    }

    final visibleSchedules = (_onlyMyList
            ? _schedules.where((s) {
                final mid = s['media']?['id'] as int?;
                return mid != null && myMediaIds.contains(mid);
              })
            : _schedules)
        .where((s) => s['media']?['isAdult'] != true)
        .toList();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(
          'Airing Schedule',
          style: AppTypography.style(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: context.appTextPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              selected: _onlyMyList,
              onSelected: (v) {
                setState(() => _onlyMyList = v);
                _loadScheduleForDay(_selectedDayIndex);
              },
              selectedColor: accent.withValues(alpha: 0.2),
              checkmarkColor: accent,
              visualDensity: VisualDensity.compact,
              label: Text(
                'My List',
                style: AppTypography.style(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: _onlyMyList ? accent : context.appTextSecondary,
                ),
              ),
              side: BorderSide(color: _onlyMyList ? accent : context.appBorder),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 7-day horizontal selector strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: context.appBackground,
            child: SizedBox(
              height: 60,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = _days[index];
                  final isSelected = _selectedDayIndex == index;
                  final dayTitle = _getDayTitle(index);
                  final dayNumber = DateFormat('d MMM').format(date);

                  return GestureDetector(
                    onTap: () => _loadScheduleForDay(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      decoration: BoxDecoration(
                        color: isSelected ? accent : context.appSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : context.appBorder,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayTitle,
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : context.appTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dayNumber,
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : context.appTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Date indicator subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                  style: TextStyle(
                    fontFamily: 'Overpass',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.appTextSecondary,
                  ),
                ),
                Text(
                  '${visibleSchedules.length} Airing',
                  style: AppTypography.style(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),

          // Schedules list
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.p16),
                    child: ShimmerMediaGrid(count: 6),
                  )
                : visibleSchedules.isEmpty
                    ? EmptyView(
                        title: _onlyMyList
                            ? 'None of your list anime air on this date'
                            : 'No anime airing on this date',
                        subtitle: _onlyMyList
                            ? 'Toggle off "My List Only" or check another day.'
                            : 'Check other days of the week above!',
                        icon: Icons.calendar_today_rounded,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.p16, 8, AppSpacing.p16, 24),
                        itemCount: visibleSchedules.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final schedule = visibleSchedules[index];
                          final media = schedule['media'] as Map<String, dynamic>?;
                          final title = TextUtil.getPreferredTitle(media?['title']);
                          final banner = media?['bannerImage'] as String?;
                          final cover = (media?['coverImage']?['extraLarge'] ??
                              media?['coverImage']?['large'] ??
                              media?['coverImage']?['medium']) as String?;
                          final episode = schedule['episode'] as int? ?? 1;
                          final airingAt = schedule['airingAt'] as int?;
                          final timeUntil = schedule['timeUntilAiring'] as int?;
                          final format = media?['format'] as String? ?? 'TV';
                          final genres = (media?['genres'] as List?)?.cast<String>() ?? [];

                          final exactTime = airingAt != null
                              ? DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(airingAt * 1000))
                              : '';
                          final countdown = DateUtil.formatCountdown(timeUntil);
                          final isAired = timeUntil != null && timeUntil <= 0;
                          final formatLabel = TextUtil.formatMediaFormat(format);

                          return TactileScale(
                            onTap: () {
                              final id = media?['id'] as int?;
                              if (id != null) {
                                Navigator.of(context).push(
                                  AppPageRoute(
                                    page: MediaDetailScreen(mediaId: id),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: context.appSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.appBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: context.isDark ? 0.22 : 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  if (banner != null && banner.isNotEmpty)
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: context.isDark ? 0.20 : 0.12,
                                        child: AppNetworkImage(
                                          imageUrl: banner,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        // Cover image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: AppNetworkImage(
                                            imageUrl: cover,
                                            width: 70,
                                            height: 102,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Airing badge row
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isAired
                                                          ? context.appInputSurface
                                                          : AppColors.statusBehind.withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      isAired ? 'Aired' : 'Ep $episode in $countdown',
                                                      style: TextStyle(
                                                        fontFamily: 'Overpass',
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: isAired ? AppColors.scoreHigh : AppColors.statusBehind,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    exactTime,
                                                    style: TextStyle(
                                                      fontFamily: 'Overpass',
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: context.appTextMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),

                                              // Title
                                              Text(
                                                title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Overpass',
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13.5,
                                                  color: context.appTextPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),

                                              // Episode & Format & Genres
                                              Text(
                                                'Episode $episode • $formatLabel${genres.isNotEmpty ? ' • ${genres.take(2).join(', ')}' : ''}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Overpass',
                                                  fontSize: 10.5,
                                                  color: context.appTextSecondary,
                                                ),
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
                          ).animateEntrance(index: index);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
