import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/theme/app_typography.dart';

/// Reusable modal video player supporting HTML5 WebM/MP4 videos and YouTube embeds.
class InAppVideoDialog {
  InAppVideoDialog._();

  static void show(
    BuildContext context, {
    required String url,
    required bool isYoutube,
    required Color accentColor,
    String? title,
  }) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: const Color(0xFF111827),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isYoutube ? Icons.play_circle_fill_rounded : Icons.movie_rounded,
                    color: accentColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title ?? (isYoutube ? 'YouTube Video' : 'Video Player'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.style(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, color: Colors.white70, size: 18),
                    tooltip: 'Open externally',
                    onPressed: () async {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: InlineVideoWebView(
                url: url,
                isYoutube: isYoutube,
                autoplayWithSound: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared inline 16:9 WebView player for HTML5 `<video>` streams and YouTube embeds.
class InlineVideoWebView extends StatefulWidget {
  final String url;
  final bool isYoutube;
  final bool autoplayWithSound;

  const InlineVideoWebView({
    super.key,
    required this.url,
    required this.isYoutube,
    this.autoplayWithSound = false,
  });

  @override
  State<InlineVideoWebView> createState() => _InlineVideoWebViewState();
}

class _InlineVideoWebViewState extends State<InlineVideoWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);

    if (widget.isYoutube) {
      _controller.loadRequest(Uri.parse(_toYoutubeEmbedUrl(widget.url)));
    } else {
      final escaped = _htmlEscapeAttr(widget.url);
      final mutedAttr = widget.autoplayWithSound ? '' : 'muted';
      final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; display: flex; align-items: center; justify-content: center; overflow: hidden; }
    video { width: 100%; height: 100%; object-fit: contain; outline: none; }
  </style>
</head>
<body>
  <video controls autoplay loop playsinline $mutedAttr preload="auto">
    <source src="$escaped" />
  </video>
</body>
</html>
''';
      _controller.loadHtmlString(html);
    }
  }

  static String _toYoutubeEmbedUrl(String url) {
    final m = RegExp(r'(?:v=|youtu\.be/|embed/)([A-Za-z0-9_-]{6,})').firstMatch(url);
    final id = m?.group(1);
    return id != null ? 'https://www.youtube.com/embed/$id?autoplay=1&playsinline=1' : url;
  }

  static String _htmlEscapeAttr(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
