import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/widgets/in_app_video_dialog.dart';
import '../constants/app_colors.dart';
import '../theme/app_typography.dart';
import 'anilist_bio_parser.dart';

class AniListBioWidget extends StatefulWidget {
  final String? bio;
  final String? bioHtml;
  final Color accentColor;
  final bool isOwn;
  final bool alwaysExpanded;
  final Future<bool> Function(String newBio)? onSaveBio;

  const AniListBioWidget({
    super.key,
    required this.bio,
    this.bioHtml,
    this.accentColor = AppColors.brandBlue,
    this.isOwn = false,
    this.alwaysExpanded = false,
    this.onSaveBio,
  });

  @override
  State<AniListBioWidget> createState() => _AniListBioWidgetState();
}

class _AniListBioWidgetState extends State<AniListBioWidget> {
  bool _isExpanded = false;
  final Set<int> _revealedSpoilers = {};
  final Set<String> _activeInlineVideos = {};

  Future<void> _handleLinkTap(String? href) async {
    if (href == null || href.isEmpty) return;
    final lower = href.toLowerCase();
    // Play direct webm/mp4 video links in a sleek in-app player dialog instead of kicking out to browser
    if (lower.endsWith('.webm') || lower.endsWith('.mp4')) {
      _openVideoModal(href, isYoutube: false);
      return;
    }
    if (lower.contains('youtube.com/watch') || lower.contains('youtu.be/')) {
      _openVideoModal(href, isYoutube: true);
      return;
    }
    try {
      final uri = Uri.parse(href);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _openVideoModal(String url, {required bool isYoutube}) {
    InAppVideoDialog.show(
      context,
      url: url,
      isYoutube: isYoutube,
      accentColor: widget.accentColor,
      title: isYoutube ? 'YouTube Video' : 'Bio Video Player',
    );
  }

  void _openBioEditor() {
    if (widget.onSaveBio == null) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditBioBottomSheet(
        initialBio: widget.bio ?? '',
        accentColor: widget.accentColor,
        onSave: widget.onSaveBio!,
      ),
    );
  }

  void _openImageViewer(String url) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawBio = widget.bio?.trim();
    final htmlBio = widget.bioHtml?.trim();
    final hasBio = (htmlBio != null && htmlBio.isNotEmpty) || (rawBio != null && rawBio.isNotEmpty);

    if (!hasBio && !widget.isOwn) {
      return const SizedBox.shrink();
    }

    final isDark = context.isDark;

    if (!hasBio) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.format_quote_rounded, size: 15, color: widget.accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No bio added yet on AniList.',
                style: AppTypography.style(
                  fontSize: 12.5,
                  color: context.appTextSecondary,
                ),
              ),
            ),
            if (widget.isOwn && widget.onSaveBio != null)
              GestureDetector(
                onTap: _openBioEditor,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 13, color: widget.accentColor),
                      const SizedBox(width: 4),
                      Text(
                        'Edit Bio',
                        style: AppTypography.style(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: widget.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final blocks = AniListBioParser.parse(bioHtml: htmlBio, rawBio: rawBio);
    final rawLen = (rawBio ?? htmlBio ?? '').length;
    final hasRichBlocks = blocks.length > 2 ||
        blocks.any((b) => b is BioBlockquoteBlock || b is BioVideoBlock || b is BioMediaRowBlock);
    final isLong = !widget.alwaysExpanded && (rawLen > 210 || hasRichBlocks);

    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          _buildBlock(
            context,
            blocks[i],
            blockKeyPrefix: 'b_$i',
            isCollapsedPreview: !(_isExpanded || !isLong || widget.alwaysExpanded),
          ),
          if (i < blocks.length - 1) const SizedBox(height: 10),
        ],
      ],
    );

    if (widget.alwaysExpanded) {
      return contentColumn;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.format_quote_rounded, size: 15, color: widget.accentColor),
                ),
                const SizedBox(width: 8),
                Text(
                  'About & Bio',
                  style: AppTypography.style(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
                const Spacer(),
                if (widget.isOwn && widget.onSaveBio != null) ...[
                  GestureDetector(
                    onTap: _openBioEditor,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.appInputSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.appBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 12.5, color: widget.accentColor),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: AppTypography.style(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: context.appTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (isLong)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isExpanded = !_isExpanded;
                        if (!_isExpanded) {
                          _activeInlineVideos.clear();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? 'Show Less' : 'Read More',
                            style: AppTypography.style(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.accentColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: widget.accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Body Blocks with Non-Destructive Smooth Height Clamping
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: (_isExpanded || !isLong)
                  ? contentColumn
                  : ClipRect(
                      child: SizedBox(
                        height: 230,
                        child: Stack(
                          children: [
                            OverflowBox(
                              minHeight: 0,
                              maxHeight: double.infinity,
                              alignment: Alignment.topCenter,
                              child: contentColumn,
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 64,
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        context.appSurface.withValues(alpha: 0.0),
                                        context.appSurface,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildBlock(
    BuildContext context,
    BioBlock block, {
    required String blockKeyPrefix,
    required bool isCollapsedPreview,
  }) {
    if (block is BioDividerBlock) {
      return Divider(color: context.appBorder, height: 12, thickness: 1);
    }

    if (block is BioHeadingBlock) {
      final sizes = {1: 19.0, 2: 16.5, 3: 14.5, 4: 13.5, 5: 13.0, 6: 12.5};
      final fontSize = sizes[block.level] ?? 15.0;
      final baseStyle = AppTypography.style(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 1.32,
        color: block.level == 3 ? widget.accentColor : context.appTextPrimary,
      );
      return _buildRichText(
        context,
        spans: block.spans,
        baseStyle: baseStyle,
        align: block.align,
        keySeed: blockKeyPrefix.hashCode,
      );
    }

    if (block is BioParagraphBlock) {
      final baseStyle = AppTypography.style(
        fontSize: 13,
        height: 1.48,
        fontWeight: FontWeight.w500,
        color: context.appTextPrimary,
      );
      return _buildRichText(
        context,
        spans: block.spans,
        baseStyle: baseStyle,
        align: block.align,
        keySeed: blockKeyPrefix.hashCode,
      );
    }

    if (block is BioBlockquoteBlock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: widget.accentColor.withValues(alpha: context.isDark ? 0.11 : 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(color: widget.accentColor, width: 3.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < block.children.length; i++) ...[
              _buildBlock(
                context,
                block.children[i],
                blockKeyPrefix: '${blockKeyPrefix}_q$i',
                isCollapsedPreview: isCollapsedPreview,
              ),
              if (i < block.children.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      );
    }

    if (block is BioMediaRowBlock) {
      final wrapAlign = switch (block.align) {
        BioAlign.center => WrapAlignment.center,
        BioAlign.right => WrapAlignment.end,
        BioAlign.left => WrapAlignment.start,
      };
      final boxAlign = switch (block.align) {
        BioAlign.center => Alignment.center,
        BioAlign.right => Alignment.centerRight,
        BioAlign.left => Alignment.centerLeft,
      };

      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
          final isMulti = block.images.length > 1;

          return Align(
            alignment: boxAlign,
            child: Wrap(
              alignment: wrapAlign,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: block.images.map((img) {
                double? targetWidth;
                if (isMulti) {
                  // Fit multiple horizontal images cleanly side-by-side on mobile widths
                  final halfMax = (maxWidth - 8) / 2;
                  targetWidth = img.widthHint != null
                      ? (img.widthHint! * 0.68).clamp(72.0, halfMax)
                      : halfMax;
                } else if (img.widthHint != null) {
                  targetWidth = img.widthHint!.clamp(72.0, maxWidth);
                }

                return GestureDetector(
                  onTap: () {
                    if (img.linkUrl != null && img.linkUrl!.isNotEmpty) {
                      _handleLinkTap(img.linkUrl);
                    } else {
                      _openImageViewer(img.url);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: targetWidth ?? maxWidth,
                        maxHeight: isMulti ? 170 : 260,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: img.url,
                        width: targetWidth,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          width: targetWidth ?? 160,
                          height: isMulti ? 100 : 120,
                          color: context.appCard,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: targetWidth ?? 140,
                          height: 54,
                          color: context.appCard,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.broken_image_rounded, size: 15, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Unavailable',
                                style: AppTypography.style(fontSize: 10.5, color: context.appTextMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      );
    }

    if (block is BioVideoBlock) {
      final videoIdKey = '$blockKeyPrefix:${block.url}';
      final isPlayingInline = !isCollapsedPreview && _activeInlineVideos.contains(videoIdKey);
      final pathSegs = Uri.tryParse(block.url)?.pathSegments ?? const <String>[];
      final fileName = pathSegs.isNotEmpty ? pathSegs.last : 'Video';

      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C121D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.accentColor.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPlayingInline)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: InlineVideoWebView(
                  url: block.url,
                  isYoutube: block.isYoutube,
                  autoplayWithSound: false,
                ),
              )
            else
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (!_isExpanded && isCollapsedPreview) {
                    setState(() {
                      _isExpanded = true;
                      _activeInlineVideos.add(videoIdKey);
                    });
                  } else {
                    setState(() => _activeInlineVideos.add(videoIdKey));
                  }
                },
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.accentColor.withValues(alpha: 0.22),
                          const Color(0xFF0C121D),
                          const Color(0xFF141B29),
                        ],
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: widget.accentColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.accentColor.withValues(alpha: 0.45),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              block.isYoutube ? 'Play YouTube Video Inline' : 'Play WebM Video Inline',
                              style: AppTypography.style(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.style(
                                  fontSize: 10.5,
                                  color: Colors.white60,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    block.isYoutube ? Icons.smart_display_rounded : Icons.videocam_rounded,
                    size: 14,
                    color: widget.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      block.isYoutube ? 'YouTube Embed' : 'WebM Audio/Video ($fileName)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.style(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  if (isPlayingInline)
                    GestureDetector(
                      onTap: () => setState(() => _activeInlineVideos.remove(videoIdKey)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          'Close',
                          style: AppTypography.style(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => _openVideoModal(block.url, isYoutube: block.isYoutube),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Fullscreen',
                        style: AppTypography.style(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: widget.accentColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (block is BioListBlock) {
      final bodyStyle = AppTypography.style(
        fontSize: 13,
        height: 1.45,
        color: context.appTextPrimary,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < block.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: block.ordered ? 22 : 16,
                    child: Text(
                      block.ordered ? '${i + 1}.' : '•',
                      style: bodyStyle.copyWith(
                        fontWeight: FontWeight.w800,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildRichText(
                      context,
                      spans: block.items[i],
                      baseStyle: bodyStyle,
                      align: BioAlign.left,
                      keySeed: '${blockKeyPrefix}_li$i'.hashCode,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRichText(
    BuildContext context, {
    required List<BioInline> spans,
    required TextStyle baseStyle,
    required BioAlign align,
    required int keySeed,
  }) {
    final textAlign = switch (align) {
      BioAlign.center => TextAlign.center,
      BioAlign.right => TextAlign.right,
      BioAlign.left => TextAlign.left,
    };

    final inlineSpans = <InlineSpan>[];
    for (var i = 0; i < spans.length; i++) {
      final item = spans[i];
      if (item is BioTextSpan) {
        if (item.spoiler) {
          final spoilerId = keySeed ^ (i * 97);
          final revealed = _revealedSpoilers.contains(spoilerId);
          inlineSpans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (revealed) {
                      _revealedSpoilers.remove(spoilerId);
                    } else {
                      _revealedSpoilers.add(spoilerId);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: revealed
                        ? widget.accentColor.withValues(alpha: 0.14)
                        : (context.isDark ? const Color(0xFF1F2937) : const Color(0xFF334155)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    revealed ? item.text : 'Spoiler (Tap)',
                    style: baseStyle.copyWith(
                      fontSize: (baseStyle.fontSize ?? 13) - 0.5,
                      color: revealed ? context.appTextPrimary : Colors.white,
                      fontWeight: revealed ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
          continue;
        }

        final hasLink = item.linkUrl != null && item.linkUrl!.isNotEmpty;
        Color? textColor = baseStyle.color;
        if (hasLink) {
          textColor = widget.accentColor;
        } else if (item.colorHex != null) {
          textColor = _parseHexColor(item.colorHex!) ?? textColor;
        } else if (item.italic && !item.bold) {
          textColor = context.appTextSecondary;
        }

        final decorations = <TextDecoration>[];
        if (hasLink) decorations.add(TextDecoration.underline);
        if (item.strike) decorations.add(TextDecoration.lineThrough);

        final effectiveStyle = baseStyle.copyWith(
          fontFamily: item.code ? 'monospace' : baseStyle.fontFamily,
          fontWeight: item.bold ? FontWeight.w900 : baseStyle.fontWeight,
          fontStyle: item.italic ? FontStyle.italic : baseStyle.fontStyle,
          color: textColor,
          backgroundColor: item.code
              ? (context.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06))
              : null,
          decoration: decorations.isEmpty ? TextDecoration.none : TextDecoration.combine(decorations),
          decorationColor: widget.accentColor.withValues(alpha: 0.6),
        );

        inlineSpans.add(
          TextSpan(
            text: item.text,
            style: effectiveStyle,
            recognizer: hasLink
                ? (TapGestureRecognizer()..onTap = () => _handleLinkTap(item.linkUrl))
                : null,
          ),
        );
      }
    }

    return SizedBox(
      width: double.infinity,
      child: Text.rich(
        TextSpan(children: inlineSpans),
        textAlign: textAlign,
        strutStyle: AppTypography.strut(baseStyle.fontSize ?? 13, height: baseStyle.height ?? 1.4),
      ),
    );
  }

  Color? _parseHexColor(String hex) {
    final clean = hex.trim().replaceAll('#', '');
    if (clean.length == 6) {
      final val = int.tryParse('FF$clean', radix: 16);
      return val != null ? Color(val) : null;
    }
    if (clean.length == 3) {
      final r = clean[0] * 2;
      final g = clean[1] * 2;
      final b = clean[2] * 2;
      final val = int.tryParse('FF$r$g$b', radix: 16);
      return val != null ? Color(val) : null;
    }
    return null;
  }
}

class _EditBioBottomSheet extends StatefulWidget {
  final String initialBio;
  final Color accentColor;
  final Future<bool> Function(String newBio) onSave;

  const _EditBioBottomSheet({
    required this.initialBio,
    required this.accentColor,
    required this.onSave,
  });

  @override
  State<_EditBioBottomSheet> createState() => _EditBioBottomSheetState();
}

class _EditBioBottomSheetState extends State<_EditBioBottomSheet> {
  late final TextEditingController _controller;
  bool _isPreview = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _wrapSelection(String prefix, String suffix, {String placeholder = 'text'}) {
    HapticFeedback.selectionClick();
    final value = _controller.value;
    final text = value.text;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;

    final selected = start < end ? text.substring(start, end) : placeholder;
    final inserted = '$prefix$selected$suffix';
    final nextText = text.replaceRange(start, end, inserted);
    final cursorOffset = start + prefix.length;
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection(
        baseOffset: cursorOffset,
        extentOffset: cursorOffset + selected.length,
      ),
    );
  }

  /// Wraps the entire current line (so ~~~center~~~, ###, > always sit cleanly around inline styles).
  void _applyLineFormat(String prefix, String suffix, {String placeholder = 'text'}) {
    HapticFeedback.selectionClick();
    final value = _controller.value;
    final text = value.text;
    final sel = value.selection;
    final cursor = sel.isValid ? sel.start : text.length;

    if (text.isEmpty) {
      final inserted = '$prefix$placeholder$suffix';
      _controller.value = TextEditingValue(
        text: inserted,
        selection: TextSelection(
          baseOffset: prefix.length,
          extentOffset: prefix.length + placeholder.length,
        ),
      );
      return;
    }

    final lineStart = text.lastIndexOf('\n', (cursor - 1).clamp(0, text.length)) + 1;
    final rawEnd = text.indexOf('\n', cursor.clamp(0, text.length));
    final lineEnd = rawEnd == -1 ? text.length : rawEnd;
    final lineText = text.substring(lineStart, lineEnd);
    final body = lineText.isEmpty ? placeholder : lineText;
    final replaced = '$prefix$body$suffix';
    final nextText = text.replaceRange(lineStart, lineEnd, replaced);
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection(
        baseOffset: lineStart + prefix.length,
        extentOffset: lineStart + prefix.length + body.length,
      ),
    );
  }

  Widget _buildModeTab(String label, {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? widget.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AppTypography.style(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : context.appTextSecondary,
          ),
        ),
      ),
    );
  }

  Future<void> _promptInsertMedia({
    required String title,
    required String urlHint,
    required String Function(String url, String label) formatBuilder,
    bool askLabel = false,
  }) async {
    final urlCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(title, style: AppTypography.style(fontSize: 15.5, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (askLabel) ...[
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  labelText: 'Link Text',
                  hintText: 'My Link',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: urlCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: urlHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor, foregroundColor: Colors.white),
            child: const Text('Insert'),
          ),
        ],
      ),
    );
    if (ok == true && urlCtrl.text.trim().isNotEmpty) {
      final snippet = formatBuilder(
        urlCtrl.text.trim(),
        labelCtrl.text.trim().isEmpty ? 'Link' : labelCtrl.text.trim(),
      );
      _wrapSelection(snippet, '', placeholder: '');
    }
    urlCtrl.dispose();
    labelCtrl.dispose();
  }

  Widget _buildFormatToolChip({
    required String label,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: context.appInputSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13.5, color: widget.accentColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.style(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: context.appTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    final ok = await widget.onSave(_controller.text);
    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        constraints: BoxConstraints(maxHeight: (screenH - bottomInset) * 0.88),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit AniList Bio',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.style(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 32,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.appInputSurface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeTab(
                        'Write',
                        selected: !_isPreview,
                        onTap: () => setState(() => _isPreview = false),
                      ),
                      _buildModeTab(
                        'Preview',
                        selected: _isPreview,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _isPreview = true);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!_isPreview) ...[
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFormatToolChip(
                      label: 'B',
                      onTap: () => _wrapSelection('__', '__', placeholder: 'bold text'),
                    ),
                    const SizedBox(width: 6),
                    _buildFormatToolChip(
                      label: 'I',
                      onTap: () => _wrapSelection('_', '_', placeholder: 'italic text'),
                    ),
                    const SizedBox(width: 6),
                    _buildFormatToolChip(
                      label: 'H3',
                      onTap: () => _applyLineFormat('### ', '', placeholder: 'Heading'),
                    ),
                    const SizedBox(width: 6),
                    _buildFormatToolChip(
                      label: 'Center',
                      icon: Icons.format_align_center_rounded,
                      onTap: () => _applyLineFormat('~~~', '~~~', placeholder: 'centered text'),
                    ),
                    const SizedBox(width: 6),
                    _buildFormatToolChip(
                      label: 'Quote',
                      icon: Icons.format_quote_rounded,
                      onTap: () => _applyLineFormat('> ', '', placeholder: 'quoted text'),
                    ),
                    const SizedBox(width: 6),
                    _buildFormatToolChip(
                      label: 'Image',
                      icon: Icons.image_outlined,
                      onTap: () => _promptInsertMedia(
                        title: 'Insert Image',
                        urlHint: 'https://example.com/image.png',
                        formatBuilder: (url, _) => 'img220($url)',
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildFormatToolChip(
                      label: 'Link',
                      icon: Icons.link_rounded,
                      onTap: () => _promptInsertMedia(
                        title: 'Insert Link',
                        urlHint: 'https://anilist.co',
                        askLabel: true,
                        formatBuilder: (url, label) => '[$label]($url)',
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildFormatToolChip(
                      label: 'Spoiler',
                      icon: Icons.visibility_off_outlined,
                      onTap: () => _wrapSelection('~!', '!~', placeholder: 'spoiler'),
                    ),
                    const SizedBox(width: 6),
                    _buildFormatToolChip(
                      label: 'WebM',
                      icon: Icons.videocam_outlined,
                      onTap: () => _promptInsertMedia(
                        title: 'Insert WebM Video',
                        urlHint: 'https://example.com/clip.webm',
                        formatBuilder: (url, _) => 'webm($url)',
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildFormatToolChip(
                      label: 'YT',
                      icon: Icons.smart_display_outlined,
                      onTap: () => _promptInsertMedia(
                        title: 'Insert YouTube Video',
                        urlHint: 'https://youtube.com/watch?v=...',
                        formatBuilder: (url, _) => 'youtube($url)',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            Flexible(
              child: _isPreview
                  ? Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 150),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.appInputSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.appBorder),
                      ),
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: _controller.text.trim().isEmpty
                              ? Text(
                                  'Nothing to preview yet. Switch to Write and type your bio!',
                                  style: AppTypography.style(
                                    fontSize: 12.5,
                                    color: context.appTextMuted,
                                  ),
                                )
                              : AniListBioWidget(
                                  bio: _controller.text,
                                  accentColor: widget.accentColor,
                                  isOwn: false,
                                  alwaysExpanded: true,
                                ),
                        ),
                      ),
                    )
                  : TextField(
                      controller: _controller,
                      maxLines: 8,
                      minLines: 5,
                      style: AppTypography.style(
                        fontSize: 13,
                        color: context.appTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Supports AniList Markdown, ~~~center~~~, img220(url), webm(url), youtube(url)',
                        hintStyle: AppTypography.style(
                          fontSize: 12,
                          color: context.appTextMuted,
                        ),
                        filled: true,
                        fillColor: context.appInputSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appBorder),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  _isSaving ? 'Saving Bio...' : 'Save Bio to AniList',
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
      ),
    );
  }
}
