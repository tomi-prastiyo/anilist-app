import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_util.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/image/app_avatar.dart';
import '../../../shared/image/app_network_image.dart';
import '../data/activity_repository.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  final TextEditingController _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(activityRepositoryProvider);
      final pageData = await repo.fetchActivities(page: 1);
      final list = (pageData['activities'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) {
        setState(() {
          _activities = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(int index) async {
    final activity = _activities[index];
    final isLiked = activity['isLiked'] as bool? ?? false;
    final currentLikes = activity['likeCount'] as int? ?? 0;

    setState(() {
      activity['isLiked'] = !isLiked;
      activity['likeCount'] = isLiked ? currentLikes - 1 : currentLikes + 1;
    });

    try {
      final repo = ref.read(activityRepositoryProvider);
      await repo.toggleLike(activity['id'] as int);
    } catch (e) {
      // Revert if error
      setState(() {
        activity['isLiked'] = isLiked;
        activity['likeCount'] = currentLikes;
      });
    }
  }

  void _showNewPostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('New Activity Post'),
        content: TextField(
          controller: _postController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share your thoughts with AniList...',
            hintStyle: const TextStyle(color: AppColors.darkTextMuted),
            filled: true,
            fillColor: AppColors.darkCard,
            border: OutlineInputBorder(
              borderRadius: AppSpacing.borderRadius8,
              borderSide: const BorderSide(color: AppColors.darkBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = _postController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(context).pop();
                _postController.clear();
                final repo = ref.read(activityRepositoryProvider);
                await repo.saveTextActivity(text);
                _load();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            tooltip: 'Create post',
            onPressed: _showNewPostDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandBlue))
          : _activities.isEmpty
              ? const EmptyView(
                  title: 'No activities yet',
                  subtitle: 'Recent activities will appear here.',
                  icon: Icons.forum_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.brandBlue,
                  backgroundColor: AppColors.darkCard,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.p16),
                    itemCount: _activities.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _activities[index];
                      final type = item['__typename'] as String? ?? '';
                      final user = item['user'] as Map<String, dynamic>?;
                      final userName = user?['name'] as String? ?? 'User';
                      final avatar = user?['avatar']?['medium'] as String?;
                      final time = DateUtil.timeAgo(item['createdAt'] as int?);
                      final isLiked = item['isLiked'] as bool? ?? false;
                      final likeCount = item['likeCount'] as int? ?? 0;
                      final replyCount = item['replyCount'] as int? ?? 0;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: AppSpacing.borderRadius12,
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppAvatar(imageUrl: avatar, size: 38),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                      Text(time, style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (type == 'TextActivity')
                              Text(
                                item['text'] as String? ?? '',
                                style: const TextStyle(fontSize: 13.5, height: 1.4),
                              )
                            else if (type == 'ListActivity') ...[
                              Row(
                                children: [
                                  AppNetworkImage(
                                    imageUrl: item['media']?['coverImage']?['medium'] as String?,
                                    width: 40,
                                    height: 56,
                                    borderRadius: AppSpacing.borderRadius4,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item['status'] ?? 'Updated'} ${item['progress'] != null ? 'episode ${item['progress']}' : ''}',
                                          style: const TextStyle(
                                            color: AppColors.brandBlue,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item['media']?['title']?['userPreferred'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => _toggleLike(index),
                                  borderRadius: AppSpacing.borderRadius4,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          size: 16,
                                          color: isLiked ? AppColors.favoritePink : AppColors.darkTextSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$likeCount',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isLiked ? AppColors.favoritePink : AppColors.darkTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.darkTextSecondary),
                                    const SizedBox(width: 4),
                                    Text('$replyCount', style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                                  ],
                                ),
                              ],
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
