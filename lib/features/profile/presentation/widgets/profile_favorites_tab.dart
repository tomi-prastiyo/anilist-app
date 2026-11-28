import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/cards/media_card.dart';
import '../../../../shared/feedback/empty_view.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../../../shared/widgets/tactile_scale.dart';
import '../../../character_staff/presentation/character_detail_screen.dart';
import '../../../character_staff/presentation/staff_detail_screen.dart';
import '../../../media_detail/presentation/media_detail_screen.dart';

class ProfileFavoritesTab extends StatefulWidget {
  final List<Map<String, dynamic>> favAnime;
  final List<Map<String, dynamic>> favManga;
  final List<Map<String, dynamic>> favCharacters;
  final List<Map<String, dynamic>> favStaff;
  final List<Map<String, dynamic>> favStudios;
  final Color accentColor;
  final bool canReorder;
  final void Function(String currentCategory) onOpenReorder;

  const ProfileFavoritesTab({
    super.key,
    required this.favAnime,
    required this.favManga,
    required this.favCharacters,
    required this.favStaff,
    required this.favStudios,
    required this.accentColor,
    required this.canReorder,
    required this.onOpenReorder,
  });

  @override
  State<ProfileFavoritesTab> createState() => _ProfileFavoritesTabState();
}

class _ProfileFavoritesTabState extends State<ProfileFavoritesTab> {
  String _favFilter = 'ALL'; // 'ALL', 'ANIME', 'MANGA', 'CHARACTERS', 'STAFF', 'STUDIOS'

  @override
  Widget build(BuildContext context) {
    final favAnime = widget.favAnime;
    final favManga = widget.favManga;
    final favCharacters = widget.favCharacters;
    final favStaff = widget.favStaff;
    final favStudios = widget.favStudios;
    final accentColor = widget.accentColor;

    final allCount = favAnime.length +
        favManga.length +
        favCharacters.length +
        favStaff.length +
        favStudios.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.p16, 14, AppSpacing.p16, 28),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFavFilterChip('All ($allCount)', 'ALL', accentColor),
              const SizedBox(width: 8),
              _buildFavFilterChip('Anime (${favAnime.length})', 'ANIME', accentColor),
              const SizedBox(width: 8),
              _buildFavFilterChip('Manga (${favManga.length})', 'MANGA', accentColor),
              const SizedBox(width: 8),
              _buildFavFilterChip('Chars (${favCharacters.length})', 'CHARACTERS', accentColor),
              const SizedBox(width: 8),
              _buildFavFilterChip('Staff (${favStaff.length})', 'STAFF', accentColor),
              if (favStudios.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildFavFilterChip('Studios (${favStudios.length})', 'STUDIOS', accentColor),
              ],
            ],
          ),
        ),
        if (widget.canReorder && allCount > 1) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onOpenReorder(_favFilter == 'ALL' ? 'ANIME' : _favFilter);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_vert_rounded, size: 15, color: accentColor),
                    const SizedBox(width: 5),
                    Text(
                      'Reorder',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),

        if (_favFilter == 'ALL') ...[
          if (favAnime.isNotEmpty)
            _favMediaSection(
              'Favorite Anime',
              favAnime,
              onSeeAll: () => setState(() => _favFilter = 'ANIME'),
            ),
          if (favManga.isNotEmpty)
            _favMediaSection(
              'Favorite Manga',
              favManga,
              onSeeAll: () => setState(() => _favFilter = 'MANGA'),
            ),
          if (favCharacters.isNotEmpty)
            _favPersonSection(
              'Favorite Characters',
              favCharacters,
              isCharacter: true,
              onSeeAll: () => setState(() => _favFilter = 'CHARACTERS'),
            ),
          if (favStaff.isNotEmpty)
            _favPersonSection(
              'Favorite Staff',
              favStaff,
              isCharacter: false,
              onSeeAll: () => setState(() => _favFilter = 'STAFF'),
            ),
          if (favStudios.isNotEmpty) ...[
            Text(
              'Favorite Studios',
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: context.appTextPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildStudiosWrap(favStudios, compactPadding: true),
          ],
        ] else if (_favFilter == 'ANIME') ...[
          _buildMediaGrid(favAnime, 'No Favorite Anime Added Yet'),
        ] else if (_favFilter == 'MANGA') ...[
          _buildMediaGrid(favManga, 'No Favorite Manga Added Yet'),
        ] else if (_favFilter == 'CHARACTERS') ...[
          _buildPersonGrid(favCharacters, isCharacter: true, emptyMessage: 'No Favorite Characters Added Yet'),
        ] else if (_favFilter == 'STAFF') ...[
          _buildPersonGrid(favStaff, isCharacter: false, emptyMessage: 'No Favorite Staff Added Yet'),
        ] else if (_favFilter == 'STUDIOS') ...[
          _buildStudiosWrap(favStudios, compactPadding: false),
        ],

        if (allCount == 0)
          const EmptyView(
            title: 'No Favorites Yet',
            subtitle: 'Heart anime, manga, characters, and staff to showcase them here.',
            icon: Icons.favorite_border_rounded,
          ),
      ],
    );
  }

  Widget _buildStudiosWrap(List<Map<String, dynamic>> favStudios, {required bool compactPadding}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: favStudios.map((s) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compactPadding ? 12 : 14,
            vertical: compactPadding ? 7 : 9,
          ),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.appBorder),
          ),
          child: Text(
            s['name'] as String? ?? 'Studio',
            style: TextStyle(
              fontFamily: 'Overpass',
              fontSize: compactPadding ? 12 : 12.5,
              fontWeight: FontWeight.w700,
              color: context.appTextPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFavFilterChip(String label, String key, Color accentColor) {
    final isSelected = _favFilter == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _favFilter = key);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : context.appSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? accentColor : context.appBorder),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.28),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Overpass',
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : context.appTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _favMediaSection(
    String title,
    List<Map<String, dynamic>> items, {
    required VoidCallback onSeeAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: context.appTextPrimary,
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'View All (${items.length}) →',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.appAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final media = items[index];
              final id = media['id'] as int?;
              return SizedBox(
                width: 132,
                child: MediaCard(
                  media: media,
                  mode: MediaCardMode.grid,
                  onTap: () {
                    if (id != null) {
                      Navigator.of(context).push(
                        AppPageRoute(page: MediaDetailScreen(mediaId: id)),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _favPersonSection(
    String title,
    List<Map<String, dynamic>> items, {
    required bool isCharacter,
    required VoidCallback onSeeAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Overpass',
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: context.appTextPrimary,
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'View All (${items.length}) →',
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.appAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 154,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final name = item['name']?['userPreferred'] ?? item['name']?['full'] ?? '';
              final image = (item['image']?['large'] ?? item['image']?['medium']) as String?;

              return TactileScale(
                onTap: () {
                  final id = item['id'] as int?;
                  if (id != null) {
                    Navigator.of(context).push(
                      AppPageRoute(
                        page: isCharacter
                            ? CharacterDetailScreen(characterId: id)
                            : StaffDetailScreen(staffId: id),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 108,
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: context.appBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (image != null)
                        AppNetworkImage(imageUrl: image, fit: BoxFit.cover, borderRadius: BorderRadius.zero)
                      else
                        Center(child: Icon(Icons.person_rounded, size: 32, color: context.appTextMuted)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.45, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.90),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 7,
                        right: 7,
                        bottom: 7,
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 11,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildMediaGrid(List<Map<String, dynamic>> items, String emptyMessage) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            emptyMessage,
            style: TextStyle(fontFamily: 'Overpass', color: context.appTextSecondary),
          ),
        ),
      );
    }

    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        childAspectRatio: 0.67,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final media = items[index];
        return MediaCard(
          media: media,
          mode: MediaCardMode.grid,
          onTap: () {
            final id = media['id'] as int?;
            if (id != null) {
              Navigator.of(context).push(
                AppPageRoute(page: MediaDetailScreen(mediaId: id)),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildPersonGrid(
    List<Map<String, dynamic>> items, {
    required bool isCharacter,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            emptyMessage,
            style: TextStyle(fontFamily: 'Overpass', color: context.appTextSecondary),
          ),
        ),
      );
    }

    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final name = item['name']?['userPreferred'] ?? item['name']?['full'] ?? '';
        final image = (item['image']?['large'] ?? item['image']?['medium']) as String?;
        final occupations = (item['primaryOccupations'] as List?)?.cast<String>() ?? const [];

        return TactileScale(
          onTap: () {
            final id = item['id'] as int?;
            if (id != null) {
              Navigator.of(context).push(
                AppPageRoute(
                  page: isCharacter
                      ? CharacterDetailScreen(characterId: id)
                      : StaffDetailScreen(staffId: id),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.appBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null)
                  AppNetworkImage(imageUrl: image, fit: BoxFit.cover, borderRadius: BorderRadius.zero)
                else
                  Center(child: Icon(Icons.person_rounded, size: 42, color: context.appTextMuted)),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.48, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 9,
                  right: 9,
                  bottom: 9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 12.5,
                          height: 1.16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                          ],
                        ),
                      ),
                      if (occupations.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          occupations.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
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
