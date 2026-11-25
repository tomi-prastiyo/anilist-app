import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/yuyuyu_assets.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../../shared/widgets/tactile_scale.dart';
import '../../../character_staff/presentation/character_detail_screen.dart';

/// Atmospheric Hero Club character banner shown at top of Home when YuYuYu theme is active.
class YuYuYuHeroBanner extends ConsumerWidget {
  const YuYuYuHeroBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!context.isYuYuYu) return const SizedBox.shrink();
    final heroine = ref.watch(yuyuyuHeroineProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.p16, 2, AppSpacing.p16, 14),
      child: TactileScale(
        onTap: () => Navigator.of(context).push(
          AppPageRoute(page: CharacterDetailScreen(characterId: heroine.characterId)),
        ),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: heroine.accentColor.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: heroine.accentColor.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const AppNetworkImage(
                imageUrl: YuYuYuAssets.bannerUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.zero,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      YuYuYuAssets.twilightBg.withValues(alpha: 0.92),
                      YuYuYuAssets.twilightSurface.withValues(alpha: 0.78),
                      YuYuYuAssets.twilightBg.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: heroine.accentColor, width: 2),
                      ),
                      child: ClipOval(
                        child: AppNetworkImage(
                          imageUrl: heroine.imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: heroine.accentColor.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'SANSHU HERO CLUB',
                                  style: TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: heroine.accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            heroine.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${heroine.roleTitle} • Tap for profile',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 10.5,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.local_florist_rounded,
                      color: heroine.accentColor.withValues(alpha: 0.85),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animateEntrance(index: 0);
  }
}
