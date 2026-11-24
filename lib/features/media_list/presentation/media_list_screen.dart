import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/text_util.dart';
import '../../../shared/cards/media_card.dart';
import '../../../shared/feedback/empty_view.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/feedback/shimmer_loading.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import 'media_list_controller.dart';

class MediaListScreen extends ConsumerStatefulWidget {
  final String type; // ANIME or MANGA

  const MediaListScreen({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends ConsumerState<MediaListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MediaCardMode _cardMode = MediaCardMode.compact;
  String _searchQuery = '';
  bool _isSearching = false;

  final List<String> _statuses = [
    'CURRENT',
    'PLANNING',
    'COMPLETED',
    'PAUSED',
    'DROPPED',
    'REPEATING',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getStatusLabel(String status) {
    if (widget.type == 'ANIME') {
      if (status == 'CURRENT') return 'Watching';
    } else {
      if (status == 'CURRENT') return 'Reading';
    }
    return status[0] + status.substring(1).toLowerCase();
  }

  IconData _getLayoutIcon() {
    switch (_cardMode) {
      case MediaCardMode.grid:
        return Icons.view_list_rounded;
      case MediaCardMode.list:
        return Icons.table_rows_rounded;
      case MediaCardMode.compact:
        return Icons.grid_view_rounded;
    }
  }

  void _cycleLayoutMode() {
    setState(() {
      switch (_cardMode) {
        case MediaCardMode.grid:
          _cardMode = MediaCardMode.list;
          break;
        case MediaCardMode.list:
          _cardMode = MediaCardMode.compact;
          break;
        case MediaCardMode.compact:
          _cardMode = MediaCardMode.grid;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isGuest = authState is! Authenticated;

    if (isGuest) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.type == 'ANIME' ? 'Anime List' : 'Manga List')),
        body: EmptyView(
          title: 'Sign in to access your list',
          subtitle: 'Keep track of what you are watching, set scores, and update progress.',
          icon: Icons.bookmark_border_rounded,
          action: ElevatedButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign In to AniList'),
          ),
        ),
      );
    }

    final user = authState.user;
    final accentColor = AppColors.getProfileAccentColor(user.profileColor);
    final provider = widget.type == 'ANIME'
        ? animeListControllerProvider
        : mangaListControllerProvider;
    final listState = ref.watch(provider);

    // Compute entry count per status tab
    final Map<String, int> statusCounts = {};
    listState.whenData((lists) {
      for (final listGroup in lists) {
        final st = (listGroup['status'] as String?)?.toUpperCase() ?? '';
        final entries = (listGroup['entries'] as List?) ?? [];
        statusCounts[st] = (statusCounts[st] ?? 0) + entries.length;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Filter list...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.darkTextMuted),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Text(
                widget.type == 'ANIME' ? 'Anime List' : 'Manga List',
                style: const TextStyle(
                  fontFamily: 'Overpass',
                  fontWeight: FontWeight.w800,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
          IconButton(
            icon: Icon(_getLayoutIcon()),
            tooltip: 'Switch layout (Grid / List / Compact)',
            onPressed: _cycleLayoutMode,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: AppColors.darkTextSecondary,
          tabs: _statuses.map((status) {
            final count = statusCounts[status];
            final label = count != null
                ? '${_getStatusLabel(status)} ($count)'
                : _getStatusLabel(status);
            return Tab(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Overpass',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
        ),
      ),
      body: listState.when(
        loading: () => const ShimmerMediaGrid(count: 6),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.read(provider.notifier).loadLists(),
        ),
        data: (lists) {
          return TabBarView(
            controller: _tabController,
            children: _statuses.map((status) {
              // Find matching list group
              final listGroup = lists.firstWhere(
                (l) => (l['status'] as String?)?.toUpperCase() == status,
                orElse: () => {'entries': []},
              );

              final rawEntries = (listGroup['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];

              // Apply search filter
              final entries = rawEntries.where((entry) {
                if (_searchQuery.isEmpty) return true;
                final title = TextUtil.getPreferredTitle(entry['media']?['title']);
                return title.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              if (entries.isEmpty) {
                return EmptyView(
                  title: 'No entries in ${_getStatusLabel(status)}',
                  subtitle: 'Add anime or manga to your list to see them here.',
                  icon: Icons.movie_filter_outlined,
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref.read(provider.notifier).loadLists(),
                color: accentColor,
                backgroundColor: AppColors.darkSurface,
                child: _buildLayout(
                  entries,
                  onIncrementProgress: (entryId, mediaId, currentProgress, maxCount) {
                    HapticFeedback.lightImpact();
                    ref.read(provider.notifier).incrementProgress(
                          entryId: entryId,
                          mediaId: mediaId,
                          currentProgress: currentProgress,
                          maxEpisodesOrChapters: maxCount,
                        );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildLayout(
    List<Map<String, dynamic>> entries, {
    required void Function(int entryId, int mediaId, int currentProgress, int? maxCount)
        onIncrementProgress,
  }) {
    switch (_cardMode) {
      case MediaCardMode.grid:
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.p16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.58,
            crossAxisSpacing: AppSpacing.p12,
            mainAxisSpacing: AppSpacing.p16,
          ),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final media = entry['media'] as Map<String, dynamic>;
            return MediaCard(
              media: media,
              mode: MediaCardMode.grid,
              userProgress: entry['progress'] as int?,
              onTap: () => _navigateToDetail(context, media['id']),
            );
          },
        );

      case MediaCardMode.list:
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.p16),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.p12),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final media = entry['media'] as Map<String, dynamic>;
            final progress = entry['progress'] as int? ?? 0;
            final maxCount = media['episodes'] as int? ?? media['chapters'] as int?;

            return MediaCard(
              media: media,
              mode: MediaCardMode.list,
              userProgress: progress,
              onTap: () => _navigateToDetail(context, media['id']),
              onIncrementProgress: () => onIncrementProgress(
                entry['id'] as int,
                media['id'] as int,
                progress,
                maxCount,
              ),
            );
          },
        );

      case MediaCardMode.compact:
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: 12),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final media = entry['media'] as Map<String, dynamic>;
            final progress = entry['progress'] as int? ?? 0;
            final maxCount = media['episodes'] as int? ?? media['chapters'] as int?;

            return MediaCard(
              media: media,
              mode: MediaCardMode.compact,
              userProgress: progress,
              onTap: () => _navigateToDetail(context, media['id']),
              onIncrementProgress: () => onIncrementProgress(
                entry['id'] as int,
                media['id'] as int,
                progress,
                maxCount,
              ),
            );
          },
        );
    }
  }

  void _navigateToDetail(BuildContext context, int? mediaId) {
    if (mediaId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MediaDetailScreen(mediaId: mediaId),
        ),
      );
    }
  }
}
