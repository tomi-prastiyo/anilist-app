import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/text_util.dart';
import '../../../shared/badges/format_chip.dart';
import '../../../shared/badges/score_badge.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/image/app_network_image.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../data/calendar_repository.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<DateTime> _days;
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    // 7 days starting from today
    _days = List.generate(7, (i) => today.add(Duration(days: i)));
    _tabController = TabController(length: _days.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadDaySchedule(_days[_tabController.index]);
      }
    });

    _loadDaySchedule(_days.first);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDaySchedule(DateTime day) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(calendarRepositoryProvider);
      final schedules = await repo.fetchScheduleForDay(day);
      if (mounted) {
        setState(() {
          _schedules = schedules;
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
        title: const Text('Airing Calendar'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.brandBlue,
          labelColor: AppColors.brandBlue,
          unselectedLabelColor: AppColors.darkTextSecondary,
          tabs: _days.map((day) {
            final isToday = day.day == DateTime.now().day;
            final label = isToday ? 'Today' : DateFormat('E, MMM d').format(day);
            return Tab(text: label);
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
          : _schedules.isEmpty
              ? const EmptyView(
                  title: 'No anime airing on this day',
                  subtitle: 'Check another day of the week.',
                  icon: Icons.calendar_today_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.p16),
                  itemCount: _schedules.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _schedules[index];
                    final media = item['media'] as Map<String, dynamic>;
                    final episode = item['episode'] as int?;
                    final timeUntilAiring = item['timeUntilAiring'] as int?;
                    final title = TextUtil.getPreferredTitle(media['title']);
                    final cover = media['coverImage']?['medium'] as String?;
                    final format = media['format'] as String?;
                    final score = (media['averageScore'] as num?)?.toDouble();

                    return InkWell(
                      onTap: () {
                        final id = media['id'] as int?;
                        if (id != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => MediaDetailScreen(mediaId: id)),
                          );
                        }
                      },
                      borderRadius: AppSpacing.borderRadius12,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.p10),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: AppSpacing.borderRadius12,
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Row(
                          children: [
                            AppNetworkImage(
                              imageUrl: cover,
                              width: 55,
                              height: 75,
                              borderRadius: AppSpacing.borderRadius8,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (format != null) FormatChip(format: format),
                                      const SizedBox(width: 6),
                                      if (score != null) ScoreBadge(score: score),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Episode $episode • ${DateUtil.formatCountdown(timeUntilAiring)}',
                                    style: const TextStyle(
                                      color: AppColors.brandBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
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
    );
  }
}
