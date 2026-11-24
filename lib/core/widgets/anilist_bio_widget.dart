import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class AniListBioWidget extends StatefulWidget {
  final String? bio;
  final Color accentColor;
  final bool isOwn;

  const AniListBioWidget({
    super.key,
    required this.bio,
    this.accentColor = AppColors.brandBlue,
    this.isOwn = false,
  });

  @override
  State<AniListBioWidget> createState() => _AniListBioWidgetState();
}

class _AniListBioWidgetState extends State<AniListBioWidget> {
  bool _isExpanded = false;

  /// Preprocesses AniList-flavored markdown into standard GFM
  static String preprocessAniListMarkdown(String input) {
    var text = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 1. Convert <br> or <br/> to markdown newlines
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n\n');

    // 2. Normalize bolding __text__ to **text** so it formats reliably inside quotes e.g. "__TITLE__"
    text = text.replaceAllMapped(RegExp(r'__([^_]+)__'), (match) {
      final inner = match.group(1) ?? '';
      return '**$inner**';
    });

    // 3. Handle headers with ~~~ or quotes: # ~~~Title~~~ or # "Title"
    text = text.replaceAllMapped(RegExp(r'^(#+)\s*~~~\s*(.*?)\s*~~~', multiLine: true), (match) {
      return '${match.group(1)} ${match.group(2)}';
    });
    text = text.replaceAllMapped(RegExp(r'^(#+)\s*"(.*?)"', multiLine: true), (match) {
      return '${match.group(1)} ${match.group(2)}';
    });

    // 4. Convert ># or > # or >### to blockquote with header, stripping internal ~~~
    text = text.replaceAllMapped(RegExp(r'^\s*>\s*#+\s*(.*?)$', multiLine: true), (match) {
      final headerContent = (match.group(1) ?? '').replaceAll('~~~', '').trim();
      return '\n\n> ### $headerContent\n\n';
    });

    // 5. Standalone ~~~text~~~ centering
    text = text.replaceAllMapped(RegExp(r'~~~\s*(.*?)\s*~~~', dotAll: true), (match) {
      final inner = match.group(1)?.trim() ?? '';
      return '\n\n$inner\n\n';
    });
    text = text.replaceAll('~~~', '');

    // 6. Convert AniList image syntax: img220(url), img(url), img100%(url) -> ![img](url)
    final imgRegex = RegExp(r'img(?:\d+%?|\d+)?\((https?://[^\s\)]+)\)', caseSensitive: false);
    text = text.replaceAllMapped(imgRegex, (match) {
      final url = match.group(1);
      return '\n\n![img]($url)\n\n';
    });

    // 7. Convert webm(url) to clean video pill using native unicode escape
    final webmRegex = RegExp(r'webm\((https?://[^\s\)]+)\)', caseSensitive: false);
    text = text.replaceAllMapped(webmRegex, (match) {
      final url = match.group(1) ?? '';
      return '\n\n[\u{1F3AC} Play WebM Video]($url)\n\n';
    });

    // 8. Convert youtube(id_or_url) using native unicode escape
    final ytRegex = RegExp(r'youtube\(([^\)]+)\)', caseSensitive: false);
    text = text.replaceAllMapped(ytRegex, (match) {
      final val = match.group(1)?.trim() ?? '';
      final url = (val.startsWith('http')) ? val : 'https://www.youtube.com/watch?v=$val';
      return '\n\n[\u25B6 Watch on YouTube]($url)\n\n';
    });

    // 9. Handle spoilers ~!spoiler text!~ using native unicode escape
    final spoilerRegex = RegExp(r'~!(.*?)!~', dotAll: true);
    text = text.replaceAllMapped(spoilerRegex, (match) {
      final content = match.group(1)?.trim() ?? '';
      return '\n\n> \u26A0\uFE0F **Spoiler**\n> $content\n\n';
    });

    // 10. Clean up consecutive blank lines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  Future<void> _handleLinkTap(String? href) async {
    if (href == null || href.isEmpty) return;
    try {
      final uri = Uri.parse(href);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Widget _buildSizedImage(dynamic config, bool isDark, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: CachedNetworkImage(
              imageUrl: config.uri.toString(),
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                height: 120,
                color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 60,
                color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Image unavailable',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.appTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context, bool isDark) {
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: TextStyle(
        fontFamily: GoogleFonts.overpass().fontFamily,
        fontSize: 13,
        height: 1.5,
        color: context.appTextPrimary,
      ),
      h1: TextStyle(
        fontFamily: GoogleFonts.overpass().fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: context.appTextPrimary,
      ),
      h2: TextStyle(
        fontFamily: GoogleFonts.overpass().fontFamily,
        fontSize: 15.5,
        fontWeight: FontWeight.w800,
        color: context.appTextPrimary,
      ),
      h3: TextStyle(
        fontFamily: GoogleFonts.overpass().fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: widget.accentColor,
      ),
      h1Align: WrapAlignment.center,
      h2Align: WrapAlignment.center,
      blockquote: TextStyle(
        fontFamily: GoogleFonts.overpass().fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.appTextPrimary,
      ),
      blockquoteDecoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: widget.accentColor,
            width: 3.5,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      a: TextStyle(
        fontFamily: GoogleFonts.overpass().fontFamily,
        fontSize: 13,
        color: widget.accentColor,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.underline,
        decorationColor: widget.accentColor.withValues(alpha: 0.5),
      ),
      strong: TextStyle(
        fontFamily: GoogleFonts.overpass().fontFamily,
        fontWeight: FontWeight.w800,
        color: context.appTextPrimary,
      ),
      em: TextStyle(
        fontFamily: GoogleFonts.overpass().fontFamily,
        fontStyle: FontStyle.italic,
        color: context.appTextSecondary,
      ),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: context.appTextPrimary,
        backgroundColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawBio = widget.bio?.trim();
    final hasBio = rawBio != null && rawBio.isNotEmpty;

    if (!hasBio && !widget.isOwn) {
      return const SizedBox.shrink();
    }

    final content = hasBio
        ? rawBio
        : 'Welcome to my AniList profile! No bio written yet.';

    final processedContent = preprocessAniListMarkdown(content);
    final isLong = content.length > 200 || content.contains('\n') || content.contains('img');

    final isDark = context.isDark;

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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
                  style: TextStyle(
                    fontFamily: GoogleFonts.overpass().fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
                const Spacer(),
                if (isLong)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isExpanded = !_isExpanded);
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
                            style: TextStyle(
                              fontFamily: GoogleFonts.overpass().fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.accentColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
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

          // Content Area with Non-Destructive Height Clamping
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: (_isExpanded || !isLong)
                  ? MarkdownBody(
                      data: processedContent,
                      selectable: true,
                      onTapLink: (text, href, title) => _handleLinkTap(href),
                      sizedImageBuilder: (config) => _buildSizedImage(config, isDark, context),
                      styleSheet: _buildStyleSheet(context, isDark),
                    )
                  : ClipRect(
                      child: SizedBox(
                        height: 220,
                        child: Stack(
                          children: [
                            OverflowBox(
                              minHeight: 0,
                              maxHeight: double.infinity,
                              alignment: Alignment.topCenter,
                              child: MarkdownBody(
                                data: processedContent,
                                selectable: false,
                                onTapLink: (text, href, title) => _handleLinkTap(href),
                                sizedImageBuilder: (config) => _buildSizedImage(config, isDark, context),
                                styleSheet: _buildStyleSheet(context, isDark),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 60,
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
}
