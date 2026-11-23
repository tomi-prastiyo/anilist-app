import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class EmptyView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.p24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.p16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Icon(icon, size: 48, color: AppColors.darkTextMuted),
            ),
            const SizedBox(height: AppSpacing.p16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.p8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkTextSecondary,
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
