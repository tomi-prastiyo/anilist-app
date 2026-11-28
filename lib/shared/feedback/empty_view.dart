import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/yuyuyu_assets.dart';
import '../../core/theme/theme_provider.dart';
import '../widgets/mankai_cute_companion.dart';
import '../widgets/mankai_motifs.dart';

class EmptyView extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyView({
    super.key,
    this.title = 'No Results Found',
    this.subtitle = 'There is nothing to display here right now.',
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isYuYuYu = context.isYuYuYu;
    final heroine = ref.watch(yuyuyuHeroineProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isYuYuYu)
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: heroine.accentColor.withValues(alpha: 0.08),
                      border: Border.all(
                        color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.45),
                        width: 1,
                      ),
                    ),
                  ),
                  MankaiFloatingMascot(
                    assetPath: heroine.chibiAsset,
                    accentColor: heroine.accentColor,
                    greetingText: heroine.cuteGreeting,
                    size: 118,
                  ),
                  Positioned(
                    right: 2,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4.5),
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
                      child: MankaiBlossomGlyph(
                        size: 13,
                        color: heroine.accentColor,
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.p16),
                decoration: BoxDecoration(
                  color: context.appCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.appBorder),
                ),
                child: Icon(icon, size: 46, color: context.appTextMuted),
              ),
            const SizedBox(height: AppSpacing.p16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.appTextPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.p8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appTextSecondary,
                  ),
            ),
            if (isYuYuYu) ...[
              const SizedBox(height: AppSpacing.p8),
              Text(
                '${heroine.clubTenet} — ${heroine.name.split(' ').first}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: context.appTextMuted,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.p20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
