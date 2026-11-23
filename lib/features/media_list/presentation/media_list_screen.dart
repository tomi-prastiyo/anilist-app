import 'package:flutter/material.dart';
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
  MediaCardMode _cardMode = MediaCardMode.list;
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

    final provider = widget.type == 'ANIME'
        ? animeListControllerProvider
        : mangaListControllerProvider;
    final listState = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Filter list...',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: AppColors.darkTextMuted),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Text(widget.type == 'ANIME' ? 'Anime List' : 'Manga List'),
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
            icon: Icon(
              _cardMode == MediaCardMode.list ? Icons.grid_view_rounded : Icons.view_list_rounded,
            ),
            tooltip: 'Switch layout',
            onPressed: () {
              setState(() {
                _cardMode = _cardMode == MediaCardMode.list
                    ? MediaCardMode.grid
                    : MediaCardMode.list;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.brandBlue,
          labelColor: AppColors.brandBlue,
          unselectedLabelColor: AppColors.darkTextSecondary,
          tabs: _statuses.map((status) => Tab(text: _getStatusLabel(status))).toList(),
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
                color: AppColors.brandBlue,
                backgroundColor: AppColors.darkCard,
                child: _cardMode == MediaCardMode.grid
                    ? GridView.builder(
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
                      )
                    : ListView.separated(
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
                            onIncrementProgress: () {
                              ref.read(provider.notifier).incrementProgress(
                                    entryId: entry['id'] as int,
                                    mediaId: media['id'] as int,
                                    currentProgress: progress,
                                    maxEpisodesOrChapters: maxCount,
                                  );
                            },
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
