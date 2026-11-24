import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_util.dart';
import '../../../../shared/feedback/empty_view.dart';
import '../../../../shared/image/app_avatar.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../media_detail/presentation/media_detail_screen.dart';
import '../../../profile/presentation/profile_screen.dart';
import '../../data/activity_repository.dart';

class ActivityCommentsBottomSheet extends ConsumerStatefulWidget {
  final int activityId;
  final String? activityUserName;
  final String? activityUserAvatar;
  final String? activityTitle;
  final Map<String, dynamic>? media;
  final String? activityStatus;
  final String? activityProgress;
  final int initialReplyCount;
  final VoidCallback? onReplyAdded;

  const ActivityCommentsBottomSheet({
    super.key,
    required this.activityId,
    this.activityUserName,
    this.activityUserAvatar,
    this.activityTitle,
    this.media,
    this.activityStatus,
    this.activityProgress,
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
  Map<String, dynamic>? _media;
  String? _activityStatus;
  String? _activityProgress;
  String? _authorName;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _media = widget.media;
    _activityStatus = widget.activityStatus;
    _activityProgress = widget.activityProgress;
    _authorName = widget.activityUserName;
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

      if (_media == null) {
        try {
          final detail = await repo.fetchActivityDetail(widget.activityId);
          if (detail != null && mounted) {
            _media = detail['media'] as Map<String, dynamic>?;
            _activityStatus = detail['status'] as String?;
            _activityProgress = detail['progress'] != null ? '${detail['progress']}' : null;
            final user = detail['user'] as Map<String, dynamic>?;
            if (user?['name'] != null) _authorName = user!['name'] as String;
          }
        } catch (_) {}
      }

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
                    const Icon(Icons.chat_bubble_rounded, size: 18, color: AppColors.brandBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Comments (${_replies.length})',
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

          // Activity / Media Context Card
          if (_media != null) ...[
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
          ] else if (widget.activityUserName != null || widget.activityTitle != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.appBackground.withValues(alpha: 0.6),
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
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 12,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

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
                                                style: TextStyle(
                                                  fontFamily: 'Overpass',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: context.appTextPrimary,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              relativeTime,
                                              style: TextStyle(
                                                fontFamily: 'Overpass',
                                                fontSize: 11,
                                                color: context.appTextMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        // Comment Text Box
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: context.appBackground.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: context.appBorder),
                                          ),
                                          child: Text(
                                            text,
                                            style: TextStyle(
                                              fontFamily: 'Overpass',
                                              fontSize: 13,
                                              height: 1.4,
                                              color: context.appTextPrimary,
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
                                                  color: isLiked ? AppColors.favoritePink : context.appTextMuted,
                                                ),
                                                if (likeCount > 0) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$likeCount',
                                                    style: TextStyle(
                                                      fontFamily: 'Overpass',
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: isLiked ? AppColors.favoritePink : context.appTextMuted,
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
                      color: context.appInputSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.appBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
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
                            style: TextStyle(fontSize: 13.5, color: context.appTextPrimary),
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              hintStyle: TextStyle(
                                color: context.appTextMuted,
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
                    child: Text(
                      'Sign in to join the conversation',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 12.5,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
