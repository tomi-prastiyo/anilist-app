import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/notifications/presentation/notification_read_controller.dart';
import '../../features/notifications/presentation/notifications_screen.dart';

/// AppBar notification bell with live unread badge synchronized across Home & Profile.
class NotificationBellButton extends ConsumerWidget {
  final bool darkBackdrop;

  const NotificationBellButton({
    super.key,
    this.darkBackdrop = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! Authenticated) return const SizedBox.shrink();

    final unreadCount = ref.watch(
      notificationReadProvider.select((s) => s.unreadCount),
    );
    final badgeLabel = unreadCount > 99 ? '99+' : '$unreadCount';

    Future<void> openNotifications() async {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    }

    if (darkBackdrop) {
      return IconButton(
        tooltip: 'Notifications',
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: _UnreadBadgePill(label: badgeLabel),
              ),
          ],
        ),
        onPressed: openNotifications,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: openNotifications,
        ),
        if (unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: IgnorePointer(child: _UnreadBadgePill(label: badgeLabel)),
          ),
      ],
    );
  }
}

class _UnreadBadgePill extends StatelessWidget {
  final String label;

  const _UnreadBadgePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.statusBehind,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.25), width: 0.8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          height: 1.05,
        ),
      ),
    );
  }
}
