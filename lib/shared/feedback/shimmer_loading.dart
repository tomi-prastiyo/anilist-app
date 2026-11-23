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
