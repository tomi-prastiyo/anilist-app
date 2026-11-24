import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/image/app_avatar.dart';
import '../../../character_staff/presentation/character_detail_screen.dart';
import '../../../character_staff/presentation/staff_detail_screen.dart';

class CharacterDualCard extends StatelessWidget {
  final Map<String, dynamic> character;
  final String role;
  final Map<String, dynamic>? voiceActor;

  const CharacterDualCard({
    super.key,
    required this.character,
    required this.role,
    this.voiceActor,
  });

  @override
  Widget build(BuildContext context) {
    final charId = character['id'] as int?;
    final charName = character['name']?['userPreferred'] ?? character['name']?['full'] ?? 'Unknown';
    final charImage = character['image']?['medium'] as String?;
    final isMain = role.toUpperCase() == 'MAIN';

    final vaId = voiceActor?['id'] as int?;
    final vaName = voiceActor?['name']?['userPreferred'] ?? voiceActor?['name']?['full'];
    final vaImage = voiceActor?['image']?['medium'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: AppSpacing.borderRadius12,
        border: Border.all(
          color: isMain
              ? const Color(0xFFFFB703).withValues(alpha: 0.25)
              : context.appBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Character
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              onTap: charId != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CharacterDetailScreen(characterId: charId),
                        ),
                      );
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    AppAvatar(imageUrl: charImage, size: 44),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            charName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: context.appTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isMain
                                  ? const Color(0xFFFFB703).withValues(alpha: 0.15)
                                  : (context.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isMain ? 'MAIN' : 'SUPPORT',
                              style: TextStyle(
                                fontFamily: 'Overpass',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isMain ? const Color(0xFFFFB703) : context.appTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 40,
            color: context.appBorder,
          ),

          // Right: Voice Actor (Seiyuu)
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
              onTap: vaId != null
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StaffDetailScreen(staffId: vaId),
                        ),
                      );
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: vaName != null
                    ? Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  vaName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: 'Overpass',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: context.appTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.mic_rounded, size: 10, color: AppColors.brandBlue),
                                    SizedBox(width: 3),
                                    Text(
                                      'Japanese',
                                      style: TextStyle(
                                        fontFamily: 'Overpass',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.brandBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppAvatar(imageUrl: vaImage, size: 44),
                        ],
                      )
                    : Container(
                        alignment: Alignment.center,
                        child: Text(
                          'No VA listed',
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 11,
                            color: context.appTextMuted,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
