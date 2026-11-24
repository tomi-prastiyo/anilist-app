import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/text_util.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/image/app_network_image.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../data/home_repository.dart';

class AiringScheduleScreen extends ConsumerStatefulWidget {
  const AiringScheduleScreen({super.key});

  @override
  ConsumerState<AiringScheduleScreen> createState() => _AiringScheduleScreenState();
}

class _AiringScheduleScreenState extends ConsumerState<AiringScheduleScreen> {
  int _selectedDayIndex = 0;
  bool _isLoading = true;
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

  Future<void> _loadScheduleForDay(int dayIndex) async {
    setState(() {
      _selectedDayIndex = dayIndex;
      _isLoading = true;
    });

    final targetDate = _days[dayIndex];
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day).millisecondsSinceEpoch ~/ 1000;
    final endOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59).millisecondsSinceEpoch ~/ 1000;

    try {
      final repo = ref.read(homeRepositoryProvider);
      final list = await repo.fetchAiringSchedule(
        airingAtGreater: startOfDay,
        airingAtLesser: endOfDay,
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

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text(
          'Airing Schedule',
          style: TextStyle(
            fontFamily: 'Overpass',
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
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
                        color: isSelected ? AppColors.brandBlue : context.appSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandBlue
                              : context.appBorder,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.brandBlue.withValues(alpha: 0.35),
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
                                  ? context.appBackground.withValues(alpha: 0.8)
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
                  '${_schedules.length} Airing',
                  style: const TextStyle(
                    fontFamily: 'Overpass',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandBlue,
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
                : _schedules.isEmpty
                    ? const EmptyView(
                        title: 'No anime airing on this date',
                        subtitle: 'Check other days of the week above!',
                        icon: Icons.calendar_today_rounded,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: 8),
                        itemCount: _schedules.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final schedule = _schedules[index];
                          final media = schedule['media'] as Map<String, dynamic>?;
                          final title = TextUtil.getPreferredTitle(media?['title']);
                          final cover = (media?['coverImage']?['large'] ?? media?['coverImage']?['medium']) as String?;
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

                          return GestureDetector(
                            onTap: () {
                              final id = media?['id'] as int?;
                              if (id != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MediaDetailScreen(mediaId: id),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: context.appSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.appBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Cover image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: AppNetworkImage(
                                      imageUrl: cover,
                                      width: 58,
                                      height: 84,
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
                                                isAired ? 'Aired • $exactTime' : 'Ep $episode in $countdown',
                                                style: TextStyle(
                                                  fontFamily: 'Overpass',
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: isAired ? context.appTextSecondary : AppColors.statusBehind,
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
                                            fontSize: 13,
                                            color: context.appTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),

                                        // Episode & Format & Genres
                                        Text(
                                          'Episode $episode • $format${genres.isNotEmpty ? ' • ${genres.take(2).join(', ')}' : ''}',
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
