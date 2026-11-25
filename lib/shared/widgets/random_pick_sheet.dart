import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/animations/app_motion.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/text_util.dart';
import '../../features/media_detail/presentation/media_detail_screen.dart';
import '../image/app_network_image.dart';
import 'tactile_scale.dart';

/// Fun random recommendation sheet ("Spin to Watch") picking from a list of media maps.
class RandomPickSheet extends StatefulWidget {
  final List<Map<String, dynamic>> mediaList;
  final String titlePreference;
  final String contextTitle;

  const RandomPickSheet({
    super.key,
    required this.mediaList,
    required this.titlePreference,
    required this.contextTitle,
  });

  static void show(
    BuildContext context, {
    required List<Map<String, dynamic>> mediaList,
    String titlePreference = 'ROMAJI',
    String contextTitle = 'Random Pick',
  }) {
    if (mediaList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No titles available to pick from.')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => RandomPickSheet(
        mediaList: mediaList,
        titlePreference: titlePreference,
        contextTitle: contextTitle,
      ),
    );
  }

  @override
  State<RandomPickSheet> createState() => _RandomPickSheetState();
}

class _RandomPickSheetState extends State<RandomPickSheet> {
  final _rng = Random();
  late int _pickedIndex;
  int _spinCount = 0;

  @override
  void initState() {
    super.initState();
    _pickedIndex = _rng.nextInt(widget.mediaList.length);
  }

  void _spinAgain() {
    if (widget.mediaList.length <= 1) return;
    HapticFeedback.lightImpact();
    var next = _rng.nextInt(widget.mediaList.length);
    if (next == _pickedIndex) {
      next = (next + 1) % widget.mediaList.length;
    }
    setState(() {
      _pickedIndex = next;
      _spinCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.mediaList[_pickedIndex];
    final id = media['id'] as int?;
    final title = TextUtil.getPreferredTitle(media['title'], preference: widget.titlePreference);
    final cover = (media['coverImage']?['extraLarge'] ??
        media['coverImage']?['large'] ??
        media['coverImage']?['medium']) as String?;
    final format = TextUtil.formatMediaFormat(media['format'] as String?);
    final avgScore = media['averageScore'] as int?;
    final genres = (media['genres'] as List?)?.cast<String>() ?? [];
    final accent = context.appAccent;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.appBorder),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.appBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.casino_rounded, color: accent, size: 18),
                const SizedBox(width: 6),
                Text(
                  widget.contextTitle,
                  style: AppTypography.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutBack,
              child: Column(
                key: ValueKey('${id}_$_spinCount'),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.5),
                      child: AppNetworkImage(
                        imageUrl: cover,
                        width: 136,
                        height: 196,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.style(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: context.appTextPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      if (format.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.appInputSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: context.appBorder),
                          ),
                          child: Text(
                            format,
                            style: AppTypography.style(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.appTextSecondary,
                            ),
                          ),
                        ),
                      if (avgScore != null && avgScore > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF46C07B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '★ $avgScore%',
                            style: AppTypography.style(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF46C07B),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (genres.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      genres.take(3).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.style(
                        fontSize: 11.5,
                        color: context.appTextMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TactileScale(
                    onTap: widget.mediaList.length > 1 ? _spinAgain : null,
                    child: OutlinedButton.icon(
                      onPressed: widget.mediaList.length > 1 ? _spinAgain : null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.appBorder),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.refresh_rounded, size: 18, color: context.appTextPrimary),
                      label: Text(
                        'Spin Again',
                        style: AppTypography.style(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: context.appTextPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: id == null
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              AppPageRoute(page: MediaDetailScreen(mediaId: id)),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: Text(
                      'View Details',
                      style: AppTypography.style(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
