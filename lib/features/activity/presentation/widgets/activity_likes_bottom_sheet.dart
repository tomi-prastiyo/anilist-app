import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/feedback/empty_view.dart';
import '../../../../shared/image/app_avatar.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../media_detail/presentation/media_detail_screen.dart';
import '../../../profile/presentation/profile_screen.dart';
import '../../data/activity_repository.dart';

class ActivityLikesBottomSheet extends ConsumerStatefulWidget {
  final int activityId;
  final Map<String, dynamic>? media;
  final String? activityStatus;
  final String? activityProgress;
  final String? activityUserName;
  final List<Map<String, dynamic>>? initialLikes;

  const ActivityLikesBottomSheet({
    super.key,
    required this.activityId,
    this.media,
    this.activityStatus,
    this.activityProgress,
    this.activityUserName,
    this.initialLikes,
  });

  @override
  ConsumerState<ActivityLikesBottomSheet> createState() => _ActivityLikesBottomSheetState();
}

class _ActivityLikesBottomSheetState extends ConsumerState<ActivityLikesBottomSheet> {
  List<Map<String, dynamic>> _likes = [];
  Map<String, dynamic>? _media;
  String? _activityStatus;
  String? _activityProgress;
  String? _authorName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _media = widget.media;
    _activityStatus = widget.activityStatus;
    _activityProgress = widget.activityProgress;
    _authorName = widget.activityUserName;
    _likes = widget.initialLikes ?? [];

    if (_likes.isEmpty || _media == null) {
      _loadActivityDetails();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadActivityDetails() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(activityRepositoryProvider);
      final detail = await repo.fetchActivityDetail(widget.activityId);
      if (detail != null && mounted) {
        final rawLikes = detail['likes'] as List?;
        final parsedLikes = rawLikes?.cast<Map<String, dynamic>>() ?? [];
        final user = detail['user'] as Map<String, dynamic>?;

        setState(() {
          _likes = parsedLikes;
          _media ??= detail['media'] as Map<String, dynamic>?;
          _activityStatus ??= detail['status'] as String?;
          if (_activityProgress == null && detail['progress'] != null) {
            _activityProgress = '${detail['progress']}';
          }
          if (_authorName == null && user?['name'] != null) {
            _authorName = user!['name'] as String;
          }
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, size: 18, color: AppColors.favoritePink),
                    const SizedBox(width: 8),
                    Text(
                      'Liked by (${_likes.length})',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: context.appTextSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Media Context Card (Explains what anime/manga was liked)
          if (_media != null)
            InkWell(
              onTap: () {
                final mediaId = _media!['id'] as int?;
                if (mediaId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MediaDetailScreen(mediaId: mediaId),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.appBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.appBorder),
                ),
                child: Row(
                  children: [
                    AppNetworkImage(
                      imageUrl: _media!['coverImage']?['medium'],
                      width: 36,
                      height: 48,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.brandBlue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _media!['type'] ?? 'MEDIA',
                                  style: const TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brandBlue,
                                  ),
                                ),
                              ),
                              if (_activityStatus != null && _activityStatus!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '$_activityStatus ${_activityProgress ?? ''}'.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Overpass',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.scoreHigh,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _media!['title']?['userPreferred'] ??
                                _media!['title']?['romaji'] ??
                                _media!['title']?['english'] ??
                                '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: context.appTextPrimary,
                            ),
                          ),
                          if (_authorName != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              'Post by $_authorName',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 20, color: context.appTextSecondary),
                  ],
                ),
              ),
            ),

          const Divider(color: Colors.white10, height: 1),

          // Likers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
                : _likes.isEmpty
                    ? const EmptyView(
                        title: 'No likes yet',
                        subtitle: 'Be the first to like this activity!',
                        icon: Icons.favorite_border_rounded,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: _likes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = _likes[index];
                          final id = user['id'] as int;
                          final name = user['name'] as String? ?? 'User';
                          final avatar = user['avatar']?['medium'] as String?;
                          final isFollowing = user['isFollowing'] as bool? ?? false;
                          final isFollower = user['isFollower'] as bool? ?? false;

                          return InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => ProfileScreen(userId: id)),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  AppAvatar(imageUrl: avatar, size: 40),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontFamily: 'Overpass',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: context.appTextPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isFollowing && isFollower)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.scoreHigh.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Mutual',
                                        style: TextStyle(
                                          fontFamily: 'Overpass',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.scoreHigh,
                                        ),
                                      ),
                                    )
                                  else if (isFollower)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandBlue.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Follows you',
                                        style: TextStyle(
                                          fontFamily: 'Overpass',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.brandBlue,
                                        ),
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
