import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_util.dart';
import '../../../../shared/feedback/empty_view.dart';
import '../../../../shared/image/app_avatar.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../profile/presentation/profile_screen.dart';
import '../../data/activity_repository.dart';

class ActivityCommentsBottomSheet extends ConsumerStatefulWidget {
  final int activityId;
  final String? activityUserName;
  final String? activityUserAvatar;
  final String? activityTitle;
  final int initialReplyCount;
  final VoidCallback? onReplyAdded;

  const ActivityCommentsBottomSheet({
    super.key,
    required this.activityId,
    this.activityUserName,
    this.activityUserAvatar,
    this.activityTitle,
    this.initialReplyCount = 0,
    this.onReplyAdded,
  });

  @override
  ConsumerState<ActivityCommentsBottomSheet> createState() => _ActivityCommentsBottomSheetState();
}

class _ActivityCommentsBottomSheetState extends ConsumerState<ActivityCommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _replies = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(activityRepositoryProvider);
      final data = await repo.fetchActivityReplies(activityId: widget.activityId);
      final replies = (data['activityReplies'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (mounted) {
        setState(() {
          _replies = replies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendReply() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    HapticFeedback.lightImpact();
    setState(() => _isSending = true);

    try {
      final repo = ref.read(activityRepositoryProvider);
      final newReply = await repo.saveActivityReply(
        activityId: widget.activityId,
        text: text,
      );

      _commentController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
        setState(() {
          _replies.add(newReply);
          _isSending = false;
        });
        widget.onReplyAdded?.call();

        // Scroll to the newest comment
        Future.delayed(const Duration(milliseconds: 200), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post reply: $e'),
            backgroundColor: AppColors.statusDropped,
          ),
        );
      }
    }
  }

  Future<void> _toggleReplyLike(int index) async {
    HapticFeedback.lightImpact();
    final reply = _replies[index];
    final replyId = reply['id'] as int?;
    if (replyId == null) return;

    final isLiked = reply['isLiked'] as bool? ?? false;
    final currentLikes = reply['likeCount'] as int? ?? 0;

    setState(() {
      reply['isLiked'] = !isLiked;
      reply['likeCount'] = isLiked ? (currentLikes > 0 ? currentLikes - 1 : 0) : currentLikes + 1;
    });

    try {
      final repo = ref.read(activityRepositoryProvider);
      await repo.toggleReplyLike(replyId);
    } catch (_) {
      if (mounted) {
        setState(() {
          reply['isLiked'] = isLiked;
          reply['likeCount'] = currentLikes;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isAuthenticated = authState is Authenticated;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
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
                    const Icon(Icons.chat_bubble_rounded, size: 18, color: AppColors.brandBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Comments (${_replies.length})',
                      style: const TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.darkTextSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Activity Context Snippet (if available)
          if (widget.activityUserName != null || widget.activityTitle != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkBackground.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  if (widget.activityUserAvatar != null) ...[
                    AppAvatar(imageUrl: widget.activityUserAvatar, size: 24),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      '${widget.activityUserName ?? ''} ${widget.activityTitle ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 12,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(color: Colors.white10, height: 1),

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.brandBlue),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.statusDropped, fontSize: 13),
                        ),
                      )
                    : _replies.isEmpty
                        ? const Center(
                            child: EmptyView(
                              title: 'No comments yet',
                              subtitle: 'Be the first to join the conversation!',
                              icon: Icons.chat_bubble_outline_rounded,
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            itemCount: _replies.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final reply = _replies[index];
                              final user = reply['user'] as Map<String, dynamic>?;
                              final userId = user?['id'] as int?;
                              final userName = user?['name'] as String? ?? 'User';
                              final avatarUrl = user?['avatar']?['medium'] as String?;
                              final text = reply['text'] as String? ?? '';
                              final createdAt = reply['createdAt'] as int?;
                              final relativeTime = createdAt != null
                                  ? DateUtil.timeAgo(createdAt)
                                  : '';
                              final isLiked = reply['isLiked'] as bool? ?? false;
                              final likeCount = reply['likeCount'] as int? ?? 0;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User Avatar
                                  GestureDetector(
                                    onTap: () {
                                      if (userId != null) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => ProfileScreen(userId: userId),
                                          ),
                                        );
                                      }
                                    },
                                    child: AppAvatar(imageUrl: avatarUrl, size: 36),
                                  ),
                                  const SizedBox(width: 12),

                                  // Comment Bubble & Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // User Name & Time
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                if (userId != null) {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) => ProfileScreen(userId: userId),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Text(
                                                userName,
                                                style: const TextStyle(
                                                  fontFamily: 'Overpass',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              relativeTime,
                                              style: const TextStyle(
                                                fontFamily: 'Overpass',
                                                fontSize: 11,
                                                color: AppColors.darkTextMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        // Comment Text Box
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.darkBackground.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                          ),
                                          child: Text(
                                            text,
                                            style: const TextStyle(
                                              fontFamily: 'Overpass',
                                              fontSize: 13,
                                              height: 1.4,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        // Like on Reply
                                        GestureDetector(
                                          onTap: isAuthenticated ? () => _toggleReplyLike(index) : null,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                  size: 13,
                                                  color: isLiked ? AppColors.favoritePink : AppColors.darkTextMuted,
                                                ),
                                                if (likeCount > 0) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$likeCount',
                                                    style: TextStyle(
                                                      fontFamily: 'Overpass',
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: isLiked ? AppColors.favoritePink : AppColors.darkTextMuted,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
          ),

          // Pinned Input Field (Bottom)
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: bottomInset > 0 ? bottomInset + 8 : 24,
            ),
            child: isAuthenticated
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurfaceInput,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            maxLines: 3,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) {
                              if (!_isSending) _sendReply();
                            },
                            style: const TextStyle(fontSize: 13.5, color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              hintStyle: TextStyle(
                                color: AppColors.darkTextMuted,
                                fontSize: 13,
                                fontFamily: 'Overpass',
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _isSending ? null : _sendReply,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3DB4F2), Color(0xFF2088CA)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandBlue.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: _isSending
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: const Text(
                      'Sign in to join the conversation',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 12.5,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
