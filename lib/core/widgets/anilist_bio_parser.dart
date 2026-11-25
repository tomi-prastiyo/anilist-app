/// Pure-Dart parser for AniList bio content (`about(asHtml: true)` with raw Markdown fallback).
/// Preserves alignment (`<center>`, `~~~...~~~`, `align=...`), nested blockquotes (`>#`),
/// inline videos (`webm(...)` / `<video>` / YouTube), horizontal `img` rows, spoilers, and hybrid inline Markdown.
library;

enum BioAlign { left, center, right }

sealed class BioBlock {
  const BioBlock();
}

class BioHeadingBlock extends BioBlock {
  final int level;
  final List<BioInline> spans;
  final BioAlign align;

  const BioHeadingBlock({
    required this.level,
    required this.spans,
    this.align = BioAlign.left,
  });
}

class BioParagraphBlock extends BioBlock {
  final List<BioInline> spans;
  final BioAlign align;

  const BioParagraphBlock({
    required this.spans,
    this.align = BioAlign.left,
  });
}

class BioBlockquoteBlock extends BioBlock {
  final List<BioBlock> children;

  const BioBlockquoteBlock(this.children);
}

class BioImageItem {
  final String url;
  final double? widthHint;
  final String? linkUrl;

  const BioImageItem({
    required this.url,
    this.widthHint,
    this.linkUrl,
  });
}

class BioMediaRowBlock extends BioBlock {
  final List<BioImageItem> images;
  final BioAlign align;

  const BioMediaRowBlock({
    required this.images,
    this.align = BioAlign.left,
  });
}

class BioVideoBlock extends BioBlock {
  final String url;
  final bool isYoutube;
  final String? label;
  final BioAlign align;

  const BioVideoBlock({
    required this.url,
    required this.isYoutube,
    this.label,
    this.align = BioAlign.center,
  });
}

class BioListBlock extends BioBlock {
  final bool ordered;
  final List<List<BioInline>> items;

  const BioListBlock({
    required this.ordered,
    required this.items,
  });
}

class BioDividerBlock extends BioBlock {
  const BioDividerBlock();
}

sealed class BioInline {
  const BioInline();
}

class BioTextSpan extends BioInline {
  final String text;
  final bool bold;
  final bool italic;
  final bool strike;
  final bool code;
  final bool spoiler;
  final String? linkUrl;
  final String? colorHex;

  const BioTextSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.strike = false,
    this.code = false,
    this.spoiler = false,
    this.linkUrl,
    this.colorHex,
  });

  BioTextSpan copyWith({
    String? text,
    bool? bold,
    bool? italic,
    bool? strike,
    bool? code,
    bool? spoiler,
    String? linkUrl,
    String? colorHex,
  }) {
    return BioTextSpan(
      text ?? this.text,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      strike: strike ?? this.strike,
      code: code ?? this.code,
      spoiler: spoiler ?? this.spoiler,
      linkUrl: linkUrl ?? this.linkUrl,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}

class BioImageInline extends BioInline {
  final BioImageItem image;
  const BioImageInline(this.image);
}

class BioVideoInline extends BioInline {
  final String url;
  final bool isYoutube;
  const BioVideoInline({required this.url, required this.isYoutube});
}

class _HtmlDomNode {
  final String tag; // '#text' for text nodes, or lowercase tag name
  final String text;
  final Map<String, String> attrs;
  final List<_HtmlDomNode> children;

  _HtmlDomNode({
    required this.tag,
    this.text = '',
    this.attrs = const {},
    List<_HtmlDomNode>? children,
  }) : children = children ?? [];
}

class _InlineStyleState {
  final bool bold;
  final bool italic;
  final bool strike;
  final bool code;
  final bool spoiler;
  final String? linkUrl;
  final String? colorHex;

  const _InlineStyleState({
    this.bold = false,
    this.italic = false,
    this.strike = false,
    this.code = false,
    this.spoiler = false,
    this.linkUrl,
    this.colorHex,
  });

  _InlineStyleState merge({
    bool? bold,
    bool? italic,
    bool? strike,
    bool? code,
    bool? spoiler,
    String? linkUrl,
    String? colorHex,
  }) {
    return _InlineStyleState(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      strike: strike ?? this.strike,
      code: code ?? this.code,
      spoiler: spoiler ?? this.spoiler,
      linkUrl: linkUrl ?? this.linkUrl,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}

class AniListBioParser {
  AniListBioParser._();

  static const Set<String> _voidTags = {
    'br',
    'hr',
    'img',
    'source',
    'input',
    'meta',
    'link',
  };

  static const Set<String> _blockTags = {
    'p',
    'div',
    'center',
    'blockquote',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'ul',
    'ol',
    'li',
    'hr',
    'pre',
    'video',
    'iframe',
  };

  /// Parses AniList bio using compiled HTML when available, or falls back cleanly from raw AniList Markdown.
  static List<BioBlock> parse({String? bioHtml, String? rawBio}) {
    final htmlSource = (bioHtml != null && bioHtml.trim().isNotEmpty)
        ? bioHtml.trim()
        : rawToHtml(rawBio?.trim() ?? '');

    if (htmlSource.isEmpty) return const [];

    final root = _parseHtmlFragment(htmlSource);
    final blocks = <BioBlock>[];
    _collectBlocks(root.children, blocks, BioAlign.left, const _InlineStyleState());
    return blocks;
  }

  /// Converts raw AniList Markdown/HTML mix into normalized HTML for unified rendering & testing.
  static String rawToHtml(String raw) {
    if (raw.isEmpty) return '';
    var text = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Protect blockquotes: group consecutive `>` lines into `<blockquote>...</blockquote>`
    final lines = text.split('\n');
    final out = StringBuffer();
    var inQuote = false;
    final quoteBuf = <String>[];

    void flushQuote() {
      if (!inQuote) return;
      final inner = rawToHtml(quoteBuf.join('\n'));
      out.writeln('<blockquote>$inner</blockquote>');
      quoteBuf.clear();
      inQuote = false;
    }

    for (final line in lines) {
      final trimmedLeft = line.trimLeft();
      if (trimmedLeft.startsWith('>')) {
        inQuote = true;
        quoteBuf.add(trimmedLeft.replaceFirst(RegExp(r'^>\s?'), ''));
      } else if (inQuote && trimmedLeft.isNotEmpty) {
        // AniList lazy blockquote continuation until blank line
        quoteBuf.add(line);
      } else {
        flushQuote();
        out.writeln(line);
      }
    }
    flushQuote();

    text = out.toString();

    // Standalone centering ~~~ ... ~~~
    text = text.replaceAllMapped(
      RegExp(r'~~~\s*(.*?)\s*~~~', dotAll: true),
      (m) => '<center>${m.group(1)?.trim() ?? ''}</center>',
    );

    // Headings # .. ##### (with optional inner <center>)
    text = text.replaceAllMapped(
      RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true),
      (m) {
        final lvl = m.group(1)!.length;
        return '<h$lvl>${m.group(2)!.trim()}</h$lvl>';
      },
    );

    // Horizontal rules
    text = text.replaceAllMapped(
      RegExp(r'^\s*(?:---+|___+|\*\*\*+)\s*$', multiLine: true),
      (_) => '<hr />',
    );

    // Convert AniList media helpers if still in raw text
    text = text.replaceAllMapped(
      RegExp(r'img(\d+%?)?\((https?://[^\s\)]+)\)', caseSensitive: false),
      (m) {
        final w = m.group(1);
        final url = m.group(2)!;
        return w != null ? "<img width='$w' src='$url' />" : "<img src='$url' />";
      },
    );
    text = text.replaceAllMapped(
      RegExp(r'webm\((https?://[^\s\)]+)\)', caseSensitive: false),
      (m) => "<video controls><source src='${m.group(1)}'></video>",
    );
    text = text.replaceAllMapped(
      RegExp(r'youtube\(([^\)]+)\)', caseSensitive: false),
      (m) {
        final v = m.group(1)!.trim();
        final idMatch = RegExp(r'(?:v=|youtu\.be/|embed/)([A-Za-z0-9_-]{6,})').firstMatch(v);
        final id = idMatch?.group(1) ?? v;
        return "<iframe src='https://www.youtube.com/embed/$id'></iframe>";
      },
    );

    // Convert newlines into <br /> inside paragraphs
    final paragraphs = text.split(RegExp(r'\n{2,}'));
    final htmlParts = <String>[];
    for (final p in paragraphs) {
      final t = p.trim();
      if (t.isEmpty) continue;
      if (RegExp(r'^<(?:h[1-6]|blockquote|center|div|hr|ul|ol|video|iframe)\b', caseSensitive: false)
          .hasMatch(t)) {
        htmlParts.add(t.replaceAll('\n', '<br />'));
      } else {
        htmlParts.add('<p>${t.replaceAll('\n', '<br />')}</p>');
      }
    }
    return htmlParts.join('\n');
  }

  static void _collectBlocks(
    List<_HtmlDomNode> nodes,
    List<BioBlock> out,
    BioAlign inheritedAlign,
    _InlineStyleState style,
  ) {
    var pendingInlines = <BioInline>[];

    void flushPending() {
      if (pendingInlines.isEmpty) return;
      _emitInlineRunsAsBlocks(pendingInlines, out, inheritedAlign);
      pendingInlines = [];
    }

    for (final node in nodes) {
      if (node.tag == '#text') {
        final normalized = _normalizeTextWhitespace(node.text);
        if (normalized.isNotEmpty) {
          pendingInlines.addAll(_parseHybridInlineMarkdown(normalized, style));
        }
        continue;
      }

      if (node.tag == 'br') {
        pendingInlines.add(BioTextSpan('\n', linkUrl: style.linkUrl));
        continue;
      }

      if (node.tag == 'hr') {
        flushPending();
        out.add(const BioDividerBlock());
        continue;
      }

      if (node.tag == 'img') {
        final src = node.attrs['src']?.trim();
        if (src != null && src.isNotEmpty) {
          final widthAttr = node.attrs['width'] ?? _extractStyleWidth(node.attrs['style']);
          final parsedW = _parseWidthAttr(widthAttr);
          pendingInlines.add(
            BioImageInline(
              BioImageItem(url: src, widthHint: parsedW, linkUrl: style.linkUrl),
            ),
          );
        }
        continue;
      }

      if (node.tag == 'video') {
        flushPending();
        final src = _extractVideoSource(node);
        if (src != null) {
          out.add(BioVideoBlock(url: src, isYoutube: false, align: inheritedAlign == BioAlign.left ? BioAlign.center : inheritedAlign));
        }
        continue;
      }

      if (node.tag == 'iframe') {
        flushPending();
        final src = node.attrs['src']?.trim();
        if (src != null && src.isNotEmpty) {
          out.add(BioVideoBlock(
            url: _normalizeYoutubeUrl(src),
            isYoutube: src.toLowerCase().contains('youtube') || src.toLowerCase().contains('youtu.be'),
            align: inheritedAlign == BioAlign.left ? BioAlign.center : inheritedAlign,
          ));
        }
        continue;
      }

      if (node.tag == 'blockquote') {
        flushPending();
        final innerBlocks = <BioBlock>[];
        _collectBlocks(node.children, innerBlocks, inheritedAlign, style);
        if (innerBlocks.isNotEmpty) {
          out.add(BioBlockquoteBlock(innerBlocks));
        }
        continue;
      }

      if (node.tag == 'center' || node.tag == 'div' || node.tag == 'p') {
        final cls = (node.attrs['class'] ?? '').toLowerCase();
        if (node.tag == 'div' && cls.contains('youtube')) {
          final ytSrc = (node.attrs['id'] ?? node.attrs['src'] ?? node.attrs['data-id'] ?? '').trim();
          if (ytSrc.isNotEmpty) {
            flushPending();
            out.add(BioVideoBlock(
              url: _normalizeYoutubeUrl(ytSrc),
              isYoutube: true,
              align: inheritedAlign == BioAlign.left ? BioAlign.center : inheritedAlign,
            ));
            continue;
          }
        }
        final nextAlign = _resolveAlign(node, inheritedAlign);
        final hasNestedBlock = node.children.any((c) => _blockTags.contains(c.tag));
        if (hasNestedBlock || node.tag == 'center' || node.tag == 'div') {
          flushPending();
          _collectBlocks(node.children, out, nextAlign, style);
        } else {
          flushPending();
          final pInlines = _extractInlineNodes(node.children, style);
          _emitInlineRunsAsBlocks(pInlines, out, nextAlign);
        }
        continue;
      }

      if (RegExp(r'^h[1-6]$').hasMatch(node.tag)) {
        flushPending();
        final lvl = int.tryParse(node.tag.substring(1)) ?? 2;
        final headingAlign = _detectNestedAlign(node) ?? inheritedAlign;
        final hInlines = _extractInlineNodes(node.children, style.merge(bold: true));
        if (hInlines.isNotEmpty) {
          out.add(BioHeadingBlock(level: lvl, spans: hInlines, align: headingAlign));
        }
        continue;
      }

      if (node.tag == 'ul' || node.tag == 'ol') {
        flushPending();
        final items = <List<BioInline>>[];
        for (final child in node.children) {
          if (child.tag == 'li') {
            final itemInlines = _extractInlineNodes(child.children, style);
            if (itemInlines.isNotEmpty) items.add(itemInlines);
          }
        }
        if (items.isNotEmpty) {
          out.add(BioListBlock(ordered: node.tag == 'ol', items: items));
        }
        continue;
      }

      // Inline wrapper tags (`strong`, `em`, `a`, `del`, `code`, `span`, `font`, etc.)
      final nextStyle = _applyTagStyle(node, style);
      pendingInlines.addAll(_extractInlineNodes(node.children, nextStyle));
    }

    flushPending();
  }

  /// Splits mixed inline runs so inline Videos become clean VideoBlocks and consecutive Images become centered/aligned Image Rows.
  static void _emitInlineRunsAsBlocks(
    List<BioInline> inlines,
    List<BioBlock> out,
    BioAlign align,
  ) {
    final textBuffer = <BioInline>[];
    final imageBuffer = <BioImageItem>[];

    void flushImages() {
      if (imageBuffer.isEmpty) return;
      out.add(BioMediaRowBlock(images: List.of(imageBuffer), align: align));
      imageBuffer.clear();
    }

    void flushText() {
      // Trim leading/trailing pure newlines/spaces
      while (textBuffer.isNotEmpty &&
          textBuffer.first is BioTextSpan &&
          (textBuffer.first as BioTextSpan).text.trim().isEmpty) {
        textBuffer.removeAt(0);
      }
      while (textBuffer.isNotEmpty &&
          textBuffer.last is BioTextSpan &&
          (textBuffer.last as BioTextSpan).text.trim().isEmpty) {
        textBuffer.removeLast();
      }
      if (textBuffer.isEmpty) return;
      out.add(BioParagraphBlock(spans: List.of(textBuffer), align: align));
      textBuffer.clear();
    }

    for (final item in inlines) {
      if (item is BioImageInline) {
        if (textBuffer.any((e) => e is BioTextSpan && e.text.trim().isNotEmpty)) {
          flushText();
        } else {
          textBuffer.clear();
        }
        imageBuffer.add(item.image);
      } else if (item is BioVideoInline) {
        flushImages();
        flushText();
        out.add(BioVideoBlock(
          url: item.url,
          isYoutube: item.isYoutube,
          align: align == BioAlign.left ? BioAlign.center : align,
        ));
      } else if (item is BioTextSpan) {
        if (imageBuffer.isNotEmpty) {
          if (item.text.trim().isEmpty) {
            // Whitespace between horizontal images keeps them on the same row!
            continue;
          }
          flushImages();
        }
        textBuffer.add(item);
      }
    }
    flushImages();
    flushText();
  }

  static List<BioInline> _extractInlineNodes(
    List<_HtmlDomNode> nodes,
    _InlineStyleState style,
  ) {
    final result = <BioInline>[];
    for (final node in nodes) {
      if (node.tag == '#text') {
        final t = _normalizeTextWhitespace(node.text);
        if (t.isNotEmpty) {
          result.addAll(_parseHybridInlineMarkdown(t, style));
        }
      } else if (node.tag == 'br') {
        result.add(BioTextSpan('\n', linkUrl: style.linkUrl));
      } else if (node.tag == 'img') {
        final src = node.attrs['src']?.trim();
        if (src != null && src.isNotEmpty) {
          final parsedW = _parseWidthAttr(node.attrs['width'] ?? _extractStyleWidth(node.attrs['style']));
          result.add(BioImageInline(
            BioImageItem(url: src, widthHint: parsedW, linkUrl: style.linkUrl),
          ));
        }
      } else if (node.tag == 'video') {
        final src = _extractVideoSource(node);
        if (src != null) result.add(BioVideoInline(url: src, isYoutube: false));
      } else if (node.tag == 'iframe') {
        final src = node.attrs['src']?.trim();
        if (src != null && src.isNotEmpty) {
          result.add(BioVideoInline(
            url: _normalizeYoutubeUrl(src),
            isYoutube: src.toLowerCase().contains('youtube') || src.toLowerCase().contains('youtu.be'),
          ));
        }
      } else if (node.tag == 'div' && (node.attrs['class'] ?? '').toLowerCase().contains('youtube')) {
        final ytSrc = (node.attrs['id'] ?? node.attrs['src'] ?? node.attrs['data-id'] ?? '').trim();
        if (ytSrc.isNotEmpty) {
          result.add(BioVideoInline(
            url: _normalizeYoutubeUrl(ytSrc),
            isYoutube: true,
          ));
        }
      } else {
        final childStyle = _applyTagStyle(node, style);
        result.addAll(_extractInlineNodes(node.children, childStyle));
      }
    }
    return result;
  }

  static _InlineStyleState _applyTagStyle(_HtmlDomNode node, _InlineStyleState base) {
    switch (node.tag) {
      case 'strong':
      case 'b':
        return base.merge(bold: true);
      case 'em':
      case 'i':
        return base.merge(italic: true);
      case 'del':
      case 's':
      case 'strike':
        return base.merge(strike: true);
      case 'code':
      case 'pre':
        return base.merge(code: true);
      case 'a':
        return base.merge(linkUrl: node.attrs['href'] ?? base.linkUrl);
      case 'font':
        return base.merge(colorHex: node.attrs['color'] ?? base.colorHex);
      case 'span':
        final cls = node.attrs['class'] ?? '';
        final isSpoiler = cls.contains('spoiler');
        final color = _extractStyleColor(node.attrs['style']);
        return base.merge(
          spoiler: isSpoiler ? true : base.spoiler,
          colorHex: color ?? base.colorHex,
        );
      default:
        return base;
    }
  }

  /// Parses AniList raw inline constructs that AniList leaves uncompiled inside `<center>` or `<a>`:
  /// `[label](url)`, `__bold__`, `**bold**`, `_italic_`, `*italic*`, `` `code` ``, `~~strike~~`, `~!...!~`, `img(...)`, `webm(...)`, `youtube(...)`.
  static List<BioInline> _parseHybridInlineMarkdown(
    String input,
    _InlineStyleState style, {
    int depth = 0,
  }) {
    if (input.isEmpty) return const [];
    if (depth > 4) return [_spanFromStyle(input, style)];

    final pattern = RegExp(
      r'(img(?:\d+%?)?\(https?://[^\s\)]+\))'
      r'|(webm\(https?://[^\s\)]+\))'
      r'|(youtube\([^\)]+\))'
      r'|(~!.+?!~)'
      r'|(\[[^\]]+\]\(https?://[^\s\)]+\))'
      r'|(__[^_\n]+__)'
      r'|(\*\*[^*\n]+\*\*)'
      r'|(~~[^~\n]+~~)'
      r'|(`[^`\n]+`)'
      r'|(?:(?<!\w)_([^_\n]+)_(?!\w))'
      r'|(?:(?<!\*)\*([^*\n]+)\*(?!\*))',
      caseSensitive: false,
      dotAll: false,
    );

    final out = <BioInline>[];
    var cursor = 0;

    for (final match in pattern.allMatches(input)) {
      if (match.start > cursor) {
        out.add(_spanFromStyle(input.substring(cursor, match.start), style));
      }
      final full = match.group(0)!;
      final lower = full.toLowerCase();

      if (lower.startsWith('img')) {
        final im = RegExp(r'img(\d+%?)?\((https?://[^\s\)]+)\)', caseSensitive: false).firstMatch(full);
        if (im != null) {
          out.add(BioImageInline(BioImageItem(
            url: im.group(2)!,
            widthHint: _parseWidthAttr(im.group(1)),
            linkUrl: style.linkUrl,
          )));
        }
      } else if (lower.startsWith('webm(')) {
        final url = full.substring(5, full.length - 1).trim();
        out.add(BioVideoInline(url: url, isYoutube: false));
      } else if (lower.startsWith('youtube(')) {
        final rawYt = full.substring(8, full.length - 1).trim();
        out.add(BioVideoInline(url: _normalizeYoutubeUrl(rawYt), isYoutube: true));
      } else if (full.startsWith('~!') && full.endsWith('!~')) {
        final inner = full.substring(2, full.length - 2);
        out.addAll(_parseHybridInlineMarkdown(inner, style.merge(spoiler: true), depth: depth + 1));
      } else if (full.startsWith('[')) {
        final lm = RegExp(r'^\[([^\]]+)\]\((https?://[^\s\)]+)\)$').firstMatch(full);
        if (lm != null) {
          out.addAll(_parseHybridInlineMarkdown(
            lm.group(1)!,
            style.merge(linkUrl: lm.group(2)!),
            depth: depth + 1,
          ));
        } else {
          out.add(_spanFromStyle(full, style));
        }
      } else if (full.startsWith('__') && full.endsWith('__')) {
        out.addAll(_parseHybridInlineMarkdown(
          full.substring(2, full.length - 2),
          style.merge(bold: true),
          depth: depth + 1,
        ));
      } else if (full.startsWith('**') && full.endsWith('**')) {
        out.addAll(_parseHybridInlineMarkdown(
          full.substring(2, full.length - 2),
          style.merge(bold: true),
          depth: depth + 1,
        ));
      } else if (full.startsWith('~~') && full.endsWith('~~')) {
        out.addAll(_parseHybridInlineMarkdown(
          full.substring(2, full.length - 2),
          style.merge(strike: true),
          depth: depth + 1,
        ));
      } else if (full.startsWith('`') && full.endsWith('`')) {
        out.add(_spanFromStyle(full.substring(1, full.length - 1), style.merge(code: true)));
      } else if (match.group(10) != null) {
        out.addAll(_parseHybridInlineMarkdown(
          match.group(10)!,
          style.merge(italic: true),
          depth: depth + 1,
        ));
      } else if (match.group(11) != null) {
        out.addAll(_parseHybridInlineMarkdown(
          match.group(11)!,
          style.merge(italic: true),
          depth: depth + 1,
        ));
      }

      cursor = match.end;
    }

    if (cursor < input.length) {
      out.add(_spanFromStyle(input.substring(cursor), style));
    }

    return out;
  }

  static BioTextSpan _spanFromStyle(String text, _InlineStyleState style) {
    return BioTextSpan(
      text,
      bold: style.bold,
      italic: style.italic,
      strike: style.strike,
      code: style.code,
      spoiler: style.spoiler,
      linkUrl: style.linkUrl,
      colorHex: style.colorHex,
    );
  }

  static _HtmlDomNode _parseHtmlFragment(String html) {
    final root = _HtmlDomNode(tag: 'root', children: []);
    final stack = <_HtmlDomNode>[root];

    final tokenRegex = RegExp(r'<(/?)([a-zA-Z0-9]+)([^>]*)>', dotAll: true);
    var cursor = 0;

    for (final match in tokenRegex.allMatches(html)) {
      if (match.start > cursor) {
        final rawText = html.substring(cursor, match.start);
        final decoded = decodeHtmlEntities(rawText);
        if (decoded.isNotEmpty) {
          stack.last.children.add(_HtmlDomNode(tag: '#text', text: decoded));
        }
      }

      final isClosing = match.group(1) == '/';
      final tagName = match.group(2)!.toLowerCase();
      final rawAttrs = match.group(3) ?? '';
      final isSelfClosing = _voidTags.contains(tagName) || rawAttrs.trimRight().endsWith('/');

      if (isClosing) {
        for (var i = stack.length - 1; i >= 1; i--) {
          if (stack[i].tag == tagName) {
            stack.length = i;
            break;
          }
        }
      } else {
        final attrs = _parseAttrs(rawAttrs);
        final node = _HtmlDomNode(tag: tagName, attrs: attrs, children: []);
        stack.last.children.add(node);
        if (!isSelfClosing) {
          stack.add(node);
        }
      }

      cursor = match.end;
    }

    if (cursor < html.length) {
      final trailing = decodeHtmlEntities(html.substring(cursor));
      if (trailing.isNotEmpty) {
        stack.last.children.add(_HtmlDomNode(tag: '#text', text: trailing));
      }
    }

    return root;
  }

  static Map<String, String> _parseAttrs(String raw) {
    final map = <String, String>{};
    final attrRegex = RegExp(r'''([a-zA-Z0-9_-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))''');
    for (final m in attrRegex.allMatches(raw)) {
      final k = m.group(1)!.toLowerCase();
      final v = m.group(2) ?? m.group(3) ?? m.group(4) ?? '';
      map[k] = decodeHtmlEntities(v);
    }
    return map;
  }

  static String decodeHtmlEntities(String input) {
    if (!input.contains('&')) return input;
    var out = input
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
    out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1)!);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });
    out = out.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      return code != null ? String.fromCharCode(code) : m.group(0)!;
    });
    return out;
  }

  static String _normalizeTextWhitespace(String text) {
    // Collapse pure template indentation newlines from AniList HTML blocks into spaces, preserving explicit words
    final noRawNewlines = text.replaceAll('\r', '').replaceAll('\n', ' ');
    return noRawNewlines.replaceAll(RegExp(r' {2,}'), ' ');
  }

  static BioAlign _resolveAlign(_HtmlDomNode node, BioAlign fallback) {
    if (node.tag == 'center') return BioAlign.center;
    final attrAlign = node.attrs['align']?.toLowerCase().trim();
    if (attrAlign == 'center') return BioAlign.center;
    if (attrAlign == 'right') return BioAlign.right;
    if (attrAlign == 'left') return BioAlign.left;
    final style = node.attrs['style']?.toLowerCase() ?? '';
    if (style.contains('text-align: center') || style.contains('text-align:center')) {
      return BioAlign.center;
    }
    if (style.contains('text-align: right') || style.contains('text-align:right')) {
      return BioAlign.right;
    }
    return _detectNestedAlign(node) ?? fallback;
  }

  static BioAlign? _detectNestedAlign(_HtmlDomNode node) {
    for (final child in node.children) {
      if (child.tag == 'center') return BioAlign.center;
      final a = child.attrs['align']?.toLowerCase();
      if (a == 'center') return BioAlign.center;
      if (a == 'right') return BioAlign.right;
    }
    return null;
  }

  static String? _extractVideoSource(_HtmlDomNode videoNode) {
    final direct = videoNode.attrs['src']?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    for (final c in videoNode.children) {
      if (c.tag == 'source') {
        final s = c.attrs['src']?.trim();
        if (s != null && s.isNotEmpty) return s;
      }
    }
    return null;
  }

  static String _normalizeYoutubeUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final embedMatch = RegExp(r'youtube\.com/embed/([A-Za-z0-9_-]{6,})').firstMatch(trimmed);
      if (embedMatch != null) {
        return 'https://www.youtube.com/watch?v=${embedMatch.group(1)}';
      }
      return trimmed;
    }
    if (trimmed.startsWith('//')) return 'https:$trimmed';
    return 'https://www.youtube.com/watch?v=$trimmed';
  }

  static double? _parseWidthAttr(String? w) {
    if (w == null || w.isEmpty) return null;
    final cleaned = w.toLowerCase().replaceAll('px', '').trim();
    if (cleaned.endsWith('%')) {
      final pct = double.tryParse(cleaned.replaceAll('%', ''));
      if (pct != null && pct > 0 && pct <= 100) {
        return 320.0 * (pct / 100.0);
      }
      return null;
    }
    return double.tryParse(cleaned);
  }

  static String? _extractStyleWidth(String? style) {
    if (style == null) return null;
    final m = RegExp(r'width\s*:\s*([^;]+)', caseSensitive: false).firstMatch(style);
    return m?.group(1)?.trim();
  }

  static String? _extractStyleColor(String? style) {
    if (style == null) return null;
    final m = RegExp(r'color\s*:\s*([^;]+)', caseSensitive: false).firstMatch(style);
    return m?.group(1)?.trim();
  }
}
