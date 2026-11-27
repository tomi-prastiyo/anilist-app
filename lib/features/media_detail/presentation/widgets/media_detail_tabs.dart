import 'package:flutter/material.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/text_util.dart';
import '../../../../shared/badges/format_chip.dart';
import '../../../../shared/badges/status_chip.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../character_staff/presentation/staff_detail_screen.dart';
import '../media_detail_screen.dart';
import 'character_dual_card.dart';

class MediaCharactersTab extends StatefulWidget {
  final Map<String, dynamic> media;

  const MediaCharactersTab({super.key, required this.media});

  @override
  State<MediaCharactersTab> createState() => _MediaCharactersTabState();
}

class _MediaCharactersTabState extends State<MediaCharactersTab> {
  String _characterFilter = 'ALL'; // 'ALL', 'MAIN', 'SUPPORTING'

  @override
  Widget build(BuildContext context) {
    final edges =
        (widget.media['characters']?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (edges.isEmpty) {
      return Center(
        child: Text(
          'No character information available.',
          style: TextStyle(fontFamily: 'Overpass', color: context.appTextSecondary),
        ),
      );
    }

    final mainCount = edges
        .where((e) => (e['role'] as String? ?? '').toUpperCase() == 'MAIN')
        .length;
    final supportCount = edges.length - mainCount;

    final filteredEdges = edges.where((e) {
      if (_characterFilter == 'ALL') return true;
      final role = (e['role'] as String? ?? '').toUpperCase();
      return role == _characterFilter;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 6),
          child: Row(
            children: [
              _charFilterPill('All (${edges.length})', 'ALL'),
              const SizedBox(width: 8),
              _charFilterPill('Main ($mainCount)', 'MAIN'),
              const SizedBox(width: 8),
              _charFilterPill('Supporting ($supportCount)', 'SUPPORTING'),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filteredEdges.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final edge = filteredEdges[index];
              final char = edge['node'] as Map<String, dynamic>? ?? const {};
              final role = edge['role'] as String? ?? 'SUPPORTING';
              final vaList =
                  (edge['voiceActors'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
              final va = vaList.isNotEmpty ? vaList.first : null;

              return CharacterDualCard(
                character: char,
                role: role,
                voiceActor: va,
              ).animateEntrance(index: index);
            },
          ),
        ),
      ],
    );
  }

  Widget _charFilterPill(String title, String filterKey) {
    final isSelected = _characterFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _characterFilter = filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandBlue.withValues(alpha: 0.2) : context.appCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.brandBlue : context.appBorder,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Overpass',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.brandBlue : context.appTextSecondary,
          ),
        ),
      ),
    );
  }
}

class MediaStaffTab extends StatelessWidget {
  final Map<String, dynamic> media;

  const MediaStaffTab({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final staffEdges =
        (media['staff']?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (staffEdges.isEmpty) {
      return Center(
        child: Text(
          'No staff information available.',
          style: TextStyle(fontFamily: 'Overpass', color: context.appTextSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: staffEdges.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final edge = staffEdges[index];
        final staff = edge['node'] as Map<String, dynamic>?;
        final role = edge['role'] as String? ?? 'Staff';
        final name = staff?['name']?['userPreferred'] ?? staff?['name']?['full'] ?? 'Unknown';
        final image = (staff?['image']?['large'] ?? staff?['image']?['medium']) as String?;
        final staffId = staff?['id'] as int?;

        return InkWell(
          onTap: staffId != null
              ? () {
                  Navigator.of(context).push(
                    AppPageRoute(page: StaffDetailScreen(staffId: staffId)),
                  );
                }
              : null,
          borderRadius: AppSpacing.borderRadius12,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: AppSpacing.borderRadius12,
              border: Border.all(color: context.appBorder),
              boxShadow: [
                BoxShadow(
                  color: context.isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                AppNetworkImage(
                  imageUrl: image,
                  width: 52,
                  height: 68,
                  borderRadius: AppSpacing.borderRadius8,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.appAccent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            color: context.appAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: context.appTextMuted),
              ],
            ),
          ),
        ).animateEntrance(index: index);
      },
    );
  }
}

class MediaRelationsTab extends StatelessWidget {
  final Map<String, dynamic> media;

  const MediaRelationsTab({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final relations =
        (media['relations']?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (relations.isEmpty) {
      return Center(
        child: Text(
          'No relations found.',
          style: TextStyle(fontFamily: 'Overpass', color: context.appTextSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: relations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final rel = relations[index];
        final relType = rel['relationType'] as String? ?? '';
        final relNode = rel['node'] as Map<String, dynamic>?;
        final relTitle = TextUtil.getPreferredTitle(relNode?['title']);
        final relCover =
            (relNode?['coverImage']?['large'] ?? relNode?['coverImage']?['medium']) as String?;
        final relFormat = relNode?['format'] as String?;
        final relStatus = relNode?['status'] as String?;

        return InkWell(
          onTap: () {
            final relId = relNode?['id'] as int?;
            if (relId != null) {
              Navigator.of(context).push(
                AppPageRoute(page: MediaDetailScreen(mediaId: relId)),
              );
            }
          },
          borderRadius: AppSpacing.borderRadius12,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.appCard,
              borderRadius: AppSpacing.borderRadius12,
              border: Border.all(color: context.appBorder),
              boxShadow: [
                BoxShadow(
                  color: context.isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                AppNetworkImage(
                  imageUrl: relCover,
                  width: 56,
                  height: 80,
                  borderRadius: AppSpacing.borderRadius8,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.appAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          relType.replaceAll('_', ' '),
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            color: context.appAccent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        relTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: context.appTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (relFormat != null) FormatChip(format: relFormat),
                          if (relFormat != null && relStatus != null) const SizedBox(width: 6),
                          if (relStatus != null) StatusChip(status: relStatus),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: context.appTextMuted),
              ],
            ),
          ),
        ).animateEntrance(index: index);
      },
    );
  }
}
