import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/text_util.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/image/app_avatar.dart';
import '../../../shared/image/app_network_image.dart';
import '../../../shared/state/favourite_sync_store.dart';
import '../../../shared/widgets/favourite_icon_button.dart';
import '../../../shared/widgets/tactile_scale.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../data/character_staff_repository.dart';

class StaffDetailScreen extends ConsumerStatefulWidget {
  final int staffId;

  const StaffDetailScreen({super.key, required this.staffId});

  @override
  ConsumerState<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends ConsumerState<StaffDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;
  bool _isFavourite = false;
  bool _isTogglingFav = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(characterStaffRepositoryProvider);
      final staff = await repo.fetchStaff(widget.staffId);
      if (!mounted) return;
      final resolvedFav = ref.read(favouriteSyncStoreProvider).resolve(
            FavouriteKind.staff,
            widget.staffId,
            staff['isFavourite'] as bool? ?? false,
          );
      setState(() {
        _data = staff;
        _isFavourite = resolvedFav;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFav() async {
    if (_isTogglingFav) return;
    HapticFeedback.lightImpact();
    final previous = _isFavourite;
    setState(() {
      _isTogglingFav = true;
      _isFavourite = !previous;
    });
    try {
      final repo = ref.read(characterStaffRepositoryProvider);
      await repo.toggleFavourite(staffId: widget.staffId);
      if (mounted) {
        _data?['isFavourite'] = _isFavourite;
        ref.read(favouriteSyncStoreProvider).record(
              FavouriteKind.staff,
              widget.staffId,
              _isFavourite,
              itemPreview: _data,
            );
        ref.read(favoritesRevisionProvider.notifier).state++;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFavourite = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: $e'),
            backgroundColor: AppColors.statusBehind,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingFav = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: context.appAccent)));
    }
    if (_error != null) {
      return Scaffold(appBar: AppBar(), body: ErrorView(message: _error!, onRetry: _load));
    }

    final name = _data!['name']?['userPreferred'] ?? _data!['name']?['full'] ?? 'Staff';
    final nativeName = _data!['name']?['native'] as String?;
    final imageUrl = _data!['image']?['large'] as String?;
    final description = TextUtil.stripHtml(_data!['description'] as String?);
    final occupations = (_data!['primaryOccupations'] as List?)?.join(', ');
    final charMediaEdges = (_data!['characterMedia']?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final isAuthenticated = ref.watch(authControllerProvider) is Authenticated;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          if (isAuthenticated)
            FavouriteIconButton(
              isFavourite: _isFavourite,
              isToggling: _isTogglingFav,
              onPressed: _toggleFav,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  Opacity(
                    opacity: context.isDark ? 0.28 : 0.16,
                    child: AppNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        context.appBackground.withValues(alpha: 0.35),
                        context.appBackground.withValues(alpha: 0.75),
                        context.appBackground,
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: context.appAccent.withValues(alpha: 0.45), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: AppNetworkImage(
                        imageUrl: imageUrl,
                        width: 146,
                        height: 200,
                        borderRadius: AppSpacing.borderRadius16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: context.appTextPrimary),
                      ),
                    ),
                    if (nativeName != null) ...[
                      const SizedBox(height: 3),
                      Text(nativeName, style: TextStyle(fontSize: 13.5, color: context.appTextSecondary)),
                    ],
                    if (occupations != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        occupations,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: context.appAccent, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ).animateEntrance(index: 0),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty) ...[
                  Text(
                    'About',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.appTextPrimary),
                  ),
                  const SizedBox(height: 8),
                  MarkdownBody(
                    data: description,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: TextStyle(fontSize: 13.5, color: context.appTextSecondary, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (charMediaEdges.isNotEmpty) ...[
                  Text(
                    'Roles & Characters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.appTextPrimary),
                  ),
                  const SizedBox(height: 12),
                  ...charMediaEdges.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final edge = entry.value;
                    final media = edge['node'] as Map<String, dynamic>?;
                    final mediaId = media?['id'] as int?;
                    final characters = (edge['characters'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                    final character = characters.isNotEmpty ? characters.first : null;

                    return TactileScale(
                      onTap: mediaId == null
                          ? null
                          : () => Navigator.of(context).push(
                                AppPageRoute(page: MediaDetailScreen(mediaId: mediaId)),
                              ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.appCard,
                          borderRadius: AppSpacing.borderRadius12,
                          border: Border.all(color: context.appBorder),
                        ),
                        child: Row(
                          children: [
                            if (character != null)
                              AppAvatar(imageUrl: character['image']?['medium'] as String?, size: 46),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (character != null)
                                    Text(
                                      character['name']?['userPreferred'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: context.appTextPrimary,
                                      ),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    media?['title']?['userPreferred'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            AppNetworkImage(
                              imageUrl: media?['coverImage']?['large'] as String? ??
                                  media?['coverImage']?['medium'] as String?,
                              width: 50,
                              height: 70,
                              borderRadius: AppSpacing.borderRadius8,
                            ),
                          ],
                        ),
                      ),
                    ).animateEntrance(index: idx);
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
