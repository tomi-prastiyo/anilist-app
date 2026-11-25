import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../image/app_network_image.dart';

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
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: heroine.accentColor.withValues(alpha: 0.7), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: heroine.accentColor.withValues(alpha: 0.28),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AppNetworkImage(
                    imageUrl: heroine.imageUrl,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                  ),
                ),
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
