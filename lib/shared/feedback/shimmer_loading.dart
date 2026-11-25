import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class ShimmerMediaGrid extends StatelessWidget {
  final int count;

  const ShimmerMediaGrid({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.p16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.58,
          crossAxisSpacing: AppSpacing.p12,
          mainAxisSpacing: AppSpacing.p16,
        ),
        itemCount: count,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: AppSpacing.borderRadius8,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.p8),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: AppSpacing.borderRadius4,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 10,
                width: 50,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: AppSpacing.borderRadius4,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ShimmerHorizontalRow extends StatelessWidget {
  final double height;
  final double itemWidth;
  final int count;

  const ShimmerHorizontalRow({
    super.key,
    this.height = 208,
    this.itemWidth = 144,
    this.count = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.shimmerBase : const Color(0xFFE5E7EB);
    final highlight =
        isDark ? AppColors.shimmerHighlight : const Color(0xFFF3F4F6);
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    return SizedBox(
      height: height,
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
          itemCount: count,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.p12),
          itemBuilder: (context, index) => SizedBox(
            width: itemWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: AppSpacing.borderRadius8,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.p8),
                Container(
                  height: 12,
                  width: itemWidth * 0.85,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: AppSpacing.borderRadius4,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 10,
                  width: itemWidth * 0.5,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: AppSpacing.borderRadius4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
