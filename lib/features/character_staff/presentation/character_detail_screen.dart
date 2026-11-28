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

class CharacterDetailScreen extends ConsumerStatefulWidget {
  final int characterId;

  const CharacterDetailScreen({super.key, required this.characterId});

  @override
  ConsumerState<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends ConsumerState<CharacterDetailScreen> {
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
      final character = await repo.fetchCharacter(widget.characterId);
      if (!mounted) return;
      final resolvedFav = ref.read(favouriteSyncStoreProvider).resolve(
            FavouriteKind.character,
            widget.characterId,
            character['isFavourite'] as bool? ?? false,
          );
      setState(() {
        _data = character;
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
      await repo.toggleFavourite(characterId: widget.characterId);
      if (mounted) {
        _data?['isFavourite'] = _isFavourite;
        ref.read(favouriteSyncStoreProvider).record(
              FavouriteKind.character,
              widget.characterId,
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

    final name = _data!['name']?['userPreferred'] ?? _data!['name']?['full'] ?? 'Character';
    final nativeName = _data!['name']?['native'] as String?;
    final imageUrl = _data!['image']?['large'] as String?;
    final description = TextUtil.stripHtml(_data!['description'] as String?);
    final mediaEdges = (_data!['media']?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
          // Immersive Full-Bleed Blurred Portrait Hero Header
          SizedBox(
            height: 295,
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
                        width: 148,
                        height: 204,
                        borderRadius: AppSpacing.borderRadius16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                    if (nativeName != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        nativeName,
                        style: TextStyle(fontSize: 13.5, color: context.appTextSecondary),
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
                Text(
                  'Media Appearances',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.appTextPrimary),
                ),
                const SizedBox(height: 12),
                ...mediaEdges.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final edge = entry.value;
                  final media = edge['node'] as Map<String, dynamic>?;
                  final mediaId = media?['id'] as int?;
                  final role = edge['characterRole'] as String? ?? '';
                  final vaList = (edge['voiceActors'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                  final va = vaList.isNotEmpty ? vaList.first : null;

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
                          AppNetworkImage(
                            imageUrl: media?['coverImage']?['large'] as String? ??
                                media?['coverImage']?['medium'] as String?,
                            width: 54,
                            height: 78,
                            borderRadius: AppSpacing.borderRadius8,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  media?['title']?['userPreferred'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: context.appTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(role, style: TextStyle(color: context.appAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          if (va != null) ...[
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  va['name']?['userPreferred'] ?? '',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.appTextPrimary),
                                ),
                                Text('Japanese', style: TextStyle(fontSize: 10, color: context.appTextMuted)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            AppAvatar(imageUrl: va['image']?['medium'] as String?, size: 38),
                          ],
                        ],
                      ),
                    ),
                  ).animateEntrance(index: idx);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
