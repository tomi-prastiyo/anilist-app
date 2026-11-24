import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_util.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../../shared/image/app_avatar.dart';
import '../../../shared/image/app_network_image.dart';
import '../../activity/presentation/widgets/activity_comments_bottom_sheet.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../data/notifications_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNextPage = true;
  String _selectedFilter = 'ALL'; // 'ALL', 'AIRING', 'ACTIVITY', 'FOLLOWS'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      if (_hasNextPage && !_isLoadingMore && !_isLoading) {
        _loadMore();
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasNextPage = true;
    });
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      final res = await repo.fetchNotificationsWithPageInfo(page: 1);
      final list = (res['notifications'] as List).cast<Map<String, dynamic>>();
      final hasNext = res['hasNextPage'] as bool? ?? false;
      if (mounted) {
        setState(() {
          _notifications = list;
          _hasNextPage = hasNext;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNextPage) return;
    setState(() => _isLoadingMore = true);
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      final nextPage = _currentPage + 1;
      final res = await repo.fetchNotificationsWithPageInfo(page: nextPage);
      final list = (res['notifications'] as List).cast<Map<String, dynamic>>();
      final hasNext = res['hasNextPage'] as bool? ?? false;
      if (mounted) {
        setState(() {
          _notifications.addAll(list);
          _currentPage = nextPage;
          _hasNextPage = hasNext;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notif) {
    HapticFeedback.lightImpact();
    final type = notif['__typename'] as String? ?? '';
    final media = notif['media'] as Map<String, dynamic>?;
    final mediaId = notif['animeId'] as int? ?? notif['mediaId'] as int? ?? media?['id'] as int?;
    final user = notif['user'] as Map<String, dynamic>?;
    final userId = notif['userId'] as int? ?? user?['id'] as int?;
    final activityId = notif['activityId'] as int?;

    // 1. Airing or Related Media -> Open Media Detail
    if (mediaId != null && (type.contains('Airing') || type.contains('Media'))) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MediaDetailScreen(mediaId: mediaId),
        ),
      );
      return;
    }

    // 2. Following -> Open User Profile
    if (type.contains('Following') && userId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: userId),
        ),
      );
      return;
    }

    // 3. Activity Notifications -> Open Activity Comments Bottom Sheet or User Profile
    if (activityId != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ActivityCommentsBottomSheet(
          activityId: activityId,
          activityUserName: user?['name'] as String?,
          activityUserAvatar: user?['avatar']?['medium'] as String?,
          initialReplyCount: 0,
        ),
      );
      return;
    }

    // 4. Thread Notifications -> Open Site URL
    final thread = notif['thread'] as Map<String, dynamic>?;
    final siteUrl = thread?['siteUrl'] as String?;
    if (siteUrl != null && siteUrl.isNotEmpty) {
      launchUrl(Uri.parse(siteUrl), mode: LaunchMode.externalApplication);
      return;
    }

    // 5. Fallback: if user exists, open their profile
    if (userId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: userId),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredNotifications() {
    if (_selectedFilter == 'ALL') return _notifications;

    return _notifications.where((n) {
      final type = n['__typename'] as String? ?? '';
      if (_selectedFilter == 'AIRING') {
        return type.contains('Airing');
      } else if (_selectedFilter == 'ACTIVITY') {
        return type.contains('Activity');
      } else if (_selectedFilter == 'FOLLOWS') {
        return type.contains('Following');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredNotifications();
    final airingCount = _notifications.where((n) => (n['__typename'] as String? ?? '').contains('Airing')).length;
    final activityCount = _notifications.where((n) => (n['__typename'] as String? ?? '').contains('Activity')).length;
    final followCount = _notifications.where((n) => (n['__typename'] as String? ?? '').contains('Following')).length;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Overpass',
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All (${_notifications.length})', 'ALL'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Airing ($airingCount)', 'AIRING'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Activity ($activityCount)', 'ACTIVITY'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Follows ($followCount)', 'FOLLOWS'),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const ShimmerMediaGrid(count: 6)
                : filteredList.isEmpty
                    ? EmptyView(
                        title: _selectedFilter == 'ALL'
                            ? 'No Notifications Yet'
                            : 'No $_selectedFilter Notifications',
                        subtitle: 'You are all caught up with recent updates!',
                        icon: Icons.notifications_none_rounded,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.brandBlue,
                        backgroundColor: AppColors.darkSurface,
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredList.length + (_isLoadingMore ? 1 : (_selectedFilter == 'ALL' && !_hasNextPage && filteredList.isNotEmpty ? 1 : 0)),
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == filteredList.length) {
                              if (_isLoadingMore) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.brandBlue,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                alignment: Alignment.center,
                                child: Text(
                                  'You are all caught up ✨',
                                  style: TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkTextSecondary.withValues(alpha: 0.6),
                                  ),
                                ),
                              );
                            }
                            final notif = filteredList[index];
                            return _buildNotificationCard(notif);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterKey) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = filterKey);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandBlue.withValues(alpha: 0.2) : AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.brandBlue : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Overpass',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.brandBlue : AppColors.darkTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final type = notif['__typename'] as String? ?? '';
    final time = DateUtil.timeAgo(notif['createdAt'] as int?);
    final user = notif['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String? ?? 'Someone';
    final userAvatar = user?['avatar']?['medium'] as String?;
    final media = notif['media'] as Map<String, dynamic>?;
    final mediaTitle = media?['title']?['userPreferred'] ?? media?['title']?['romaji'] ?? 'Anime';
    final mediaCover = media?['coverImage']?['medium'] as String?;
    final contextText = notif['context'] as String? ?? '';

    // Notification Presentation Logic
    String primaryText;
    String highlightPrefix = '';
    IconData badgeIcon;
    Color badgeColor;
    bool isAiring = false;

    if (type.contains('Airing')) {
      isAiring = true;
      final ep = notif['episode'];
      highlightPrefix = 'Episode $ep';
      primaryText = ' of $mediaTitle aired!';
      badgeIcon = Icons.tv_rounded;
      badgeColor = const Color(0xFF00B4D8);
    } else if (type.contains('Like')) {
      highlightPrefix = userName;
      primaryText = contextText.isNotEmpty ? ' $contextText' : ' liked your activity';
      badgeIcon = Icons.favorite_rounded;
      badgeColor = AppColors.favoritePink;
    } else if (type.contains('Reply')) {
      highlightPrefix = userName;
      primaryText = contextText.isNotEmpty ? ' $contextText' : ' replied to your activity';
      badgeIcon = Icons.chat_bubble_rounded;
      badgeColor = AppColors.brandBlue;
    } else if (type.contains('Mention')) {
      highlightPrefix = userName;
      primaryText = contextText.isNotEmpty ? ' $contextText' : ' mentioned you in an activity';
      badgeIcon = Icons.alternate_email_rounded;
      badgeColor = const Color(0xFFFFB703);
    } else if (type.contains('Message')) {
      highlightPrefix = userName;
      primaryText = contextText.isNotEmpty ? ' $contextText' : ' sent you a message';
      badgeIcon = Icons.mail_rounded;
      badgeColor = const Color(0xFFE040FB);
    } else if (type.contains('Following')) {
      highlightPrefix = userName;
      primaryText = contextText.isNotEmpty ? ' $contextText' : ' followed you';
      badgeIcon = Icons.person_add_rounded;
      badgeColor = AppColors.statusCompleted;
    } else if (type.contains('RelatedMedia')) {
      highlightPrefix = mediaTitle;
      primaryText = contextText.isNotEmpty ? ' $contextText' : ' was added to AniList';
      badgeIcon = Icons.movie_filter_rounded;
      badgeColor = const Color(0xFF00E676);
    } else if (type.contains('MediaDataChange') || type.contains('MediaMerge')) {
      final reason = notif['reason'] as String? ?? 'Data updated';
      highlightPrefix = mediaTitle;
      primaryText = ': $reason';
      badgeIcon = Icons.edit_note_rounded;
      badgeColor = const Color(0xFFFF9100);
    } else if (type.contains('Thread')) {
      final thread = notif['thread'] as Map<String, dynamic>?;
      final threadTitle = thread?['title'] as String? ?? 'forum thread';
      highlightPrefix = userName;
      primaryText = ' ${contextText.isNotEmpty ? contextText : 'commented on'} $threadTitle';
      badgeIcon = Icons.forum_rounded;
      badgeColor = const Color(0xFFFF5722);
    } else {
      highlightPrefix = userName;
      primaryText = contextText.isNotEmpty ? ' $contextText' : ' interacted with you';
      badgeIcon = Icons.notifications_rounded;
      badgeColor = AppColors.brandBlue;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNotificationTap(notif),
        borderRadius: AppSpacing.borderRadius12,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: AppSpacing.borderRadius12,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading Avatar or Action Indicator
              if (isAiring)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(badgeIcon, color: badgeColor, size: 22),
                )
              else
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppAvatar(imageUrl: userAvatar, size: 44),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(badgeIcon, color: Colors.white, size: 10),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(width: 12),

              // Title, Message & Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: highlightPrefix,
                            style: const TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(
                            text: primaryText,
                            style: const TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 11,
                        color: AppColors.darkTextMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing Media Thumbnail (for Airing notifications)
              if (isAiring && mediaCover != null) ...[
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AppNetworkImage(
                    imageUrl: mediaCover,
                    width: 38,
                    height: 52,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.darkTextMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
