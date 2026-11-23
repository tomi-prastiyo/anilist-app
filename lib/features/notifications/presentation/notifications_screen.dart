import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_util.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/image/app_avatar.dart';
import '../data/notifications_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      final list = await repo.fetchNotifications(page: 1);
      if (mounted) {
        setState(() {
          _notifications = list;
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
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
          : _notifications.isEmpty
              ? const EmptyView(
                  title: 'No new notifications',
                  subtitle: 'You are all caught up!',
                  icon: Icons.notifications_none_rounded,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.brandBlue,
                  backgroundColor: AppColors.darkCard,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.p16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final type = notif['__typename'] as String? ?? '';
                      final time = DateUtil.timeAgo(notif['createdAt'] as int?);
                      final user = notif['user'] as Map<String, dynamic>?;
                      final userName = user?['name'] as String? ?? 'Someone';
                      final avatar = user?['avatar']?['medium'] as String?;

                      String text;
                      IconData icon;
                      Color iconColor;

                      if (type.contains('Like')) {
                        text = '$userName liked your activity';
                        icon = Icons.favorite_rounded;
                        iconColor = AppColors.favoritePink;
                      } else if (type.contains('Reply')) {
                        text = '$userName replied to your activity';
                        icon = Icons.reply_rounded;
                        iconColor = AppColors.brandBlue;
                      } else if (type.contains('Airing')) {
                        final ep = notif['episode'];
                        final media = notif['media'] as Map<String, dynamic>?;
                        final title = media?['title']?['userPreferred'] ?? 'Anime';
                        text = 'Episode $ep of $title aired!';
                        icon = Icons.tv_rounded;
                        iconColor = AppColors.statusWatching;
                      } else {
                        text = '$userName followed you';
                        icon = Icons.person_add_rounded;
                        iconColor = AppColors.statusCompleted;
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: AppSpacing.borderRadius12,
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Row(
                          children: [
                            if (avatar != null)
                              AppAvatar(imageUrl: avatar, size: 40)
                            else
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: iconColor.withValues(alpha: 0.15),
                                child: Icon(icon, color: iconColor, size: 20),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    text,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    time,
                                    style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
