import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

class MediaThemeSongsCard extends StatefulWidget {
  final String animeTitle;
  final List<Map<String, dynamic>> openings;
  final List<Map<String, dynamic>> endings;
  final List<Map<String, dynamic>> insertSongs;
  final bool isLoading;

  const MediaThemeSongsCard({
    super.key,
    required this.animeTitle,
    required this.openings,
    required this.endings,
    this.insertSongs = const [],
    this.isLoading = false,
  });

  @override
  State<MediaThemeSongsCard> createState() => _MediaThemeSongsCardState();
}

class _MediaThemeSongsCardState extends State<MediaThemeSongsCard> {
  int _selectedTab = 0; // 0 = Openings, 1 = Endings

  Future<void> _openYouTube(String songName, String artist) async {
    HapticFeedback.lightImpact();
    final query = '${widget.animeTitle} $songName $artist theme';
    final url = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _copySongInfo(String songName, String artist, String type) {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: '$type: $songName by $artist'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$songName" to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.brandBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSongs = widget.openings.length + widget.endings.length + widget.insertSongs.length;

    if (!widget.isLoading && totalSongs == 0) {
      return const SizedBox.shrink();
    }

    final currentList = _selectedTab == 0 ? widget.openings : widget.endings;

    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: AppSpacing.borderRadius16,
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: context.isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note_rounded, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Theme Songs',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ],
                ),
                if (!widget.isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalSongs track${totalSongs > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.appTextSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Selector Pills (Openings vs Endings)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? const Color(0xFF00B4D8).withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedTab == 0
                              ? const Color(0xFF00B4D8).withValues(alpha: 0.6)
                              : context.appBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Openings (${widget.openings.length})',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _selectedTab == 0 ? const Color(0xFF00B4D8) : context.appTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? const Color(0xFFE040FB).withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedTab == 1
                              ? const Color(0xFFE040FB).withValues(alpha: 0.6)
                              : context.appBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Endings (${widget.endings.length})',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _selectedTab == 1 ? const Color(0xFFE040FB) : context.appTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Content
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.brandBlue),
                ),
              ),
            )
          else if (currentList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Center(
                child: Text(
                  _selectedTab == 0 ? 'No opening themes found' : 'No ending themes found',
                  style: TextStyle(
                    fontFamily: 'Overpass',
                    fontSize: 12.5,
                    color: context.appTextMuted,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 12, right: 12, top: 6, bottom: 12),
              itemCount: currentList.length,
              separatorBuilder: (context, index) => Divider(
                color: context.appBorder,
                height: 12,
              ),
              itemBuilder: (context, index) {
                final song = currentList[index];
                final type = song['type'] as String? ?? (_selectedTab == 0 ? 'OP' : 'ED');
                final name = song['name'] as String? ?? 'Unknown Title';
                final artist = song['artist'] as String? ?? 'Unknown Artist';
                final isOpening = _selectedTab == 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOpening
                              ? const Color(0xFF00B4D8).withValues(alpha: 0.15)
                              : const Color(0xFFE040FB).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isOpening
                                ? const Color(0xFF00B4D8).withValues(alpha: 0.4)
                                : const Color(0xFFE040FB).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isOpening ? const Color(0xFF00B4D8) : const Color(0xFFE040FB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Title & Artist
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Overpass',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Overpass',
                                fontSize: 11.5,
                                color: context.appTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action Buttons
                      IconButton(
                        icon: const Icon(
                          Icons.play_circle_fill_rounded,
                          size: 24,
                          color: Color(0xFFFF0033), // YouTube red
                        ),
                        tooltip: 'Play on YouTube',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _openYouTube(name, artist),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: context.appTextMuted,
                        ),
                        tooltip: 'Copy track info',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _copySongInfo(name, artist, type),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
