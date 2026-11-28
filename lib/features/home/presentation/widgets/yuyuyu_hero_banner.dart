import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/yuyuyu_assets.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../../shared/widgets/mankai_cute_companion.dart';
import '../../../../shared/widgets/mankai_motifs.dart';
import '../../../../shared/widgets/tactile_scale.dart';
import '../../../character_staff/presentation/character_detail_screen.dart';

/// Iconic Hero Terminal banner shown at top of Home when YuYuYu theme is active.
/// Displays active Heroine lore, Club Tenet, and a live 1-tap Heroine companion switcher
/// across all chapters of *Yuuki Yuuna wa Yuusha de Aru* (22 Heroes).
class YuYuYuHeroBanner extends ConsumerWidget {
  const YuYuYuHeroBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!context.isYuYuYu) return const SizedBox.shrink();
    final heroine = ref.watch(yuyuyuHeroineProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.p16, 4, AppSpacing.p16, 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.38),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: heroine.accentColor.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: const AppNetworkImage(
                imageUrl: YuYuYuAssets.bannerUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      YuYuYuAssets.twilightBg.withValues(alpha: 0.94),
                      YuYuYuAssets.twilightSurface.withValues(alpha: 0.84),
                      YuYuYuAssets.twilightBg.withValues(alpha: 0.78),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -24,
              top: -24,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      heroine.accentColor.withValues(alpha: 0.24),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TactileScale(
                  onTap: () => Navigator.of(context).push(
                    AppPageRoute(
                      page: CharacterDetailScreen(characterId: heroine.characterId),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 10, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.65),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: heroine.accentColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: heroine.accentColor, width: 2),
                            ),
                            child: ClipOval(
                              child: AppNetworkImage(
                                imageUrl: heroine.imageUrl,
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                                alignment: const Alignment(0, -0.35),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: heroine.accentColor.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.32),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MankaiBlossomGlyph(
                                      size: 10,
                                      color: heroine.accentColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        'HERO TERMINAL • ${heroine.chapterLabel.toUpperCase()}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Overpass',
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                          color: YuYuYuAssets.shinjuGoldSoft,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 3,
                                children: [
                                  Text(
                                    heroine.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Overpass',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: heroine.accentColor.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      '${heroine.flowerMotif} • ${heroine.fairyName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Overpass',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: heroine.accentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                heroine.clubTenet,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 10.5,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white.withValues(alpha: 0.84),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        MankaiFloatingMascot(
                          assetPath: heroine.fairyAsset,
                          accentColor: heroine.accentColor,
                          greetingText: heroine.cuteGreeting,
                          size: 40,
                          showBubbleOnTap: false,
                          onTap: () {
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${heroine.fairyName}: ${heroine.cuteGreeting}',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                          },
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: YuYuYuAssets.shinjuGoldSoft,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const MankaiGoldHairline(opacity: 0.85),
                Container(
                  color: YuYuYuAssets.twilightBg.withValues(alpha: 0.45),
                  padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: YuYuYuAssets.heroines.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 3),
                            itemBuilder: (context, index) {
                              final h = YuYuYuAssets.heroines[index];
                              return _HeroineQuickSwitchChip(
                                heroine: h,
                                isSelected: h.id == heroine.id,
                                onTap: () {
                                  if (h.id != heroine.id) {
                                    HapticFeedback.selectionClick();
                                    ref.read(yuyuyuHeroineProvider.notifier).setHeroine(h);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TactileScale(
                        onTap: () => _showHeroRosterSheet(context, ref, heroine),
                        child: Container(
                          key: const ValueKey('heroine_roster_button'),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: heroine.accentColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.45),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${YuYuYuAssets.heroines.length}',
                                style: const TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: YuYuYuAssets.shinjuGoldSoft,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Heroes',
                                    style: TextStyle(
                                      fontFamily: 'Overpass',
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      color: heroine.accentColor,
                                    ),
                                  ),
                                  Icon(
                                    Icons.expand_more_rounded,
                                    size: 11,
                                    color: heroine.accentColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animateEntrance(index: 0);
  }

  void _showHeroRosterSheet(
    BuildContext context,
    WidgetRef ref,
    YuYuYuHeroine activeHeroine,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final chapters = YuYuYuAssets.chapterFilters.where((c) => c != 'All').toList();
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.48,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: YuYuYuAssets.twilightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.45)),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: YuYuYuAssets.twilightBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                  child: Row(
                    children: [
                      MankaiBlossomGlyph(size: 16, color: activeHeroine.accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'YuYuYu Hero Franchise Roster (${YuYuYuAssets.heroines.length})',
                          style: const TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: YuYuYuAssets.blossomTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const MankaiGoldHairline(opacity: 0.6),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: chapters.length,
                    itemBuilder: (_, idx) {
                      final chapter = chapters[idx];
                      final members = YuYuYuAssets.byChapter(chapter);
                      final chapterTitle = members.first.chapterLabel;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    chapter,
                                    style: const TextStyle(
                                      fontFamily: 'Overpass',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: YuYuYuAssets.shinjuGoldSoft,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    chapterTitle,
                                    style: const TextStyle(
                                      fontFamily: 'Overpass',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: YuYuYuAssets.blossomTextPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${members.length}',
                                  style: const TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: YuYuYuAssets.blossomTextMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.86,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: members.length,
                              itemBuilder: (_, mIdx) {
                                final m = members[mIdx];
                                final isChosen = m.id == activeHeroine.id;
                                return TactileScale(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    ref.read(yuyuyuHeroineProvider.notifier).setHeroine(m);
                                    Navigator.of(sheetCtx).pop();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isChosen
                                          ? m.accentColor.withValues(alpha: 0.2)
                                          : YuYuYuAssets.twilightCard,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isChosen
                                            ? m.accentColor
                                            : YuYuYuAssets.twilightBorder,
                                        width: isChosen ? 1.8 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Image.asset(
                                            m.chibiAsset,
                                            fit: BoxFit.contain,
                                            filterQuality: FilterQuality.medium,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          m.shortName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Overpass',
                                            fontSize: 11,
                                            fontWeight: isChosen ? FontWeight.w900 : FontWeight.w700,
                                            color: isChosen
                                                ? m.accentColor
                                                : YuYuYuAssets.blossomTextPrimary,
                                          ),
                                        ),
                                        Text(
                                          m.flowerMotif,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Overpass',
                                            fontSize: 8.5,
                                            color: YuYuYuAssets.blossomTextMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroineQuickSwitchChip extends StatelessWidget {
  final YuYuYuHeroine heroine;
  final bool isSelected;
  final VoidCallback onTap;

  const _HeroineQuickSwitchChip({
    required this.heroine,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Switch to ${heroine.name}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        key: ValueKey('heroine_switch_${heroine.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.75,
                duration: const Duration(milliseconds: 180),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? heroine.accentColor
                          : YuYuYuAssets.shinjuGold.withValues(alpha: 0.25),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: heroine.accentColor.withValues(alpha: 0.45),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipOval(
                    child: AppNetworkImage(
                      imageUrl: heroine.imageUrl,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                heroine.shortName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? heroine.accentColor : YuYuYuAssets.blossomTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
