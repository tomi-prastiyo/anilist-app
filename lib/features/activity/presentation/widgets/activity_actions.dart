import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/activity_repository.dart';
import 'activity_comments_bottom_sheet.dart';
import 'activity_likes_bottom_sheet.dart';
import 'delete_activity_dialog.dart';

/// Shared UI helpers for Activity cards across [HomeActivityFeed] and [ActivityScreen].
class ActivityActions {
  ActivityActions._();

  static void openComments({
    required BuildContext context,
    required Map<String, dynamic> activity,
    required VoidCallback onReplyAdded,
  }) {
    final id = activity['id'] as int?;
    if (id == null) return;
    final user = activity['user'] as Map<String, dynamic>?;
    final media = activity['media'] as Map<String, dynamic>?;
    final title = media != null
        ? (media['title']?['userPreferred'] as String?)
        : activity['status'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActivityCommentsBottomSheet(
        activityId: id,
        activityUserName: user?['name'] as String?,
        activityUserAvatar: user?['avatar']?['medium'] as String?,
        activityTitle: title,
        media: media,
        activityStatus: activity['status'] as String?,
        activityProgress:
            activity['progress'] != null ? '${activity['progress']}' : null,
        initialReplyCount: activity['replyCount'] as int? ?? 0,
        onReplyAdded: onReplyAdded,
      ),
    );
  }

  static void openLikes({
    required BuildContext context,
    required Map<String, dynamic> activity,
  }) {
    final id = activity['id'] as int?;
    if (id == null) return;
    final user = activity['user'] as Map<String, dynamic>?;
    final media = activity['media'] as Map<String, dynamic>?;
    final rawLikes = activity['likes'] as List?;
    final initialLikes = rawLikes?.cast<Map<String, dynamic>>() ?? const [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActivityLikesBottomSheet(
        activityId: id,
        media: media,
        activityStatus: activity['status'] as String?,
        activityProgress:
            activity['progress'] != null ? '${activity['progress']}' : null,
        activityUserName: user?['name'] as String?,
        initialLikes: initialLikes,
      ),
    );
  }

  static Future<void> toggleLike({
    required BuildContext context,
    required WidgetRef ref,
    required Map<String, dynamic> activity,
    required Set<int> inFlightIds,
    required void Function(bool isLiked, int likeCount) applyUpdate,
    required bool Function() isMounted,
  }) async {
    final isAuthenticated = ref.read(authControllerProvider) is Authenticated;
    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in with AniList to like activities.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final activityId = activity['id'] as int?;
    if (activityId == null || inFlightIds.contains(activityId)) return;

    HapticFeedback.lightImpact();
    inFlightIds.add(activityId);

    final prevLiked = activity['isLiked'] as bool? ?? false;
    final prevLikes = activity['likeCount'] as int? ?? 0;
    final optimisticLiked = !prevLiked;
    final optimisticCount =
        prevLiked ? (prevLikes > 0 ? prevLikes - 1 : 0) : prevLikes + 1;

    applyUpdate(optimisticLiked, optimisticCount);

    try {
      final repo = ref.read(activityRepositoryProvider);
      final updated = await repo.toggleLike(activityId);
      if (isMounted()) {
        final finalLiked = updated?['isLiked'] as bool? ?? optimisticLiked;
        final finalCount = updated?['likeCount'] as int? ?? optimisticCount;
        applyUpdate(finalLiked, finalCount);
        ref.read(activityLikeSyncProvider.notifier).state = (
          id: activityId,
          isLiked: finalLiked,
          likeCount: finalCount,
        );
      }
    } catch (e) {
      if (isMounted()) {
        applyUpdate(prevLiked, prevLikes);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update like: $e'),
            backgroundColor: AppColors.statusBehind,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      inFlightIds.remove(activityId);
    }
  }

  static Future<void> confirmAndDelete({
    required BuildContext context,
    required WidgetRef ref,
    required int activityId,
    required VoidCallback onOptimisticRemove,
    required VoidCallback onRevert,
    required bool Function() isMounted,
  }) async {
    final confirmed = await showDeleteActivityConfirmDialog(context);
    if (!confirmed || !isMounted()) return;

    onOptimisticRemove();

    try {
      final ok = await ref.read(activityRepositoryProvider).deleteActivity(activityId);
      if (!ok) throw Exception('Failed to delete');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (isMounted()) {
        onRevert();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not delete activity: $e'),
            backgroundColor: AppColors.statusDropped,
          ),
        );
      }
    }
  }
}
