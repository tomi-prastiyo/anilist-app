import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/text_util.dart';
import '../../../../shared/image/app_network_image.dart';
import '../../data/profile_repository.dart';

class ReorderFavoritesSheet extends StatefulWidget {
  final ProfileRepository repo;
  final Color accentColor;
  final String initialCategory;
  final List<Map<String, dynamic>> favAnime;
  final List<Map<String, dynamic>> favManga;
  final List<Map<String, dynamic>> favCharacters;
  final List<Map<String, dynamic>> favStaff;
  final List<Map<String, dynamic>> favStudios;
  final void Function(String categoryKey, List<Map<String, dynamic>> updated) onSaved;

  const ReorderFavoritesSheet({
    super.key,
    required this.repo,
    required this.accentColor,
    required this.initialCategory,
    required this.favAnime,
    required this.favManga,
    required this.favCharacters,
    required this.favStaff,
    required this.favStudios,
    required this.onSaved,
  });

  @override
  State<ReorderFavoritesSheet> createState() => _ReorderFavoritesSheetState();
}

class _ReorderFavoritesSheetState extends State<ReorderFavoritesSheet> {
  late final Map<String, List<Map<String, dynamic>>> _lists;
  late String _activeKey;
  bool _isSaving = false;
  bool _hasChanges = false;

  static const _labels = <String, String>{
    'ANIME': 'Anime',
    'MANGA': 'Manga',
    'CHARACTERS': 'Chars',
    'STAFF': 'Staff',
    'STUDIOS': 'Studios',
  };

  @override
  void initState() {
    super.initState();
    _lists = {
      if (widget.favAnime.isNotEmpty) 'ANIME': List<Map<String, dynamic>>.from(widget.favAnime),
      if (widget.favManga.isNotEmpty) 'MANGA': List<Map<String, dynamic>>.from(widget.favManga),
      if (widget.favCharacters.isNotEmpty) 'CHARACTERS': List<Map<String, dynamic>>.from(widget.favCharacters),
      if (widget.favStaff.isNotEmpty) 'STAFF': List<Map<String, dynamic>>.from(widget.favStaff),
      if (widget.favStudios.isNotEmpty) 'STUDIOS': List<Map<String, dynamic>>.from(widget.favStudios),
    };
    _activeKey = _lists.containsKey(widget.initialCategory)
        ? widget.initialCategory
        : (_lists.keys.isNotEmpty ? _lists.keys.first : 'ANIME');
  }

  List<Map<String, dynamic>> get _currentItems => _lists[_activeKey] ?? const [];

  void _onReorder(int oldIndex, int newIndex) {
    final items = _lists[_activeKey];
    if (items == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  void _moveToTop(int index) {
    if (index <= 0) return;
    final items = _lists[_activeKey];
    if (items == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      final item = items.removeAt(index);
      items.insert(0, item);
      _hasChanges = true;
    });
  }

  Future<void> _saveCurrent() async {
    if (_isSaving || _currentItems.isEmpty) return;
    final ids = _currentItems
        .map((e) => e['id'] as int?)
        .whereType<int>()
        .toList();
    if (ids.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await widget.repo.updateFavouriteOrder(
        categoryKey: _activeKey,
        orderedIds: ids,
      );
      if (!mounted) return;
      widget.onSaved(_activeKey, List<Map<String, dynamic>>.from(_currentItems));
      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_labels[_activeKey]} order saved!'),
          backgroundColor: AppColors.scoreHigh,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reorder favorites: $e'),
          backgroundColor: AppColors.statusBehind,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _itemTitle(Map<String, dynamic> item) {
    if (_activeKey == 'ANIME' || _activeKey == 'MANGA') {
      return TextUtil.getPreferredTitle(item['title']);
    }
    if (_activeKey == 'STUDIOS') {
      return item['name'] as String? ?? 'Studio';
    }
    return item['name']?['userPreferred'] ?? item['name']?['full'] ?? 'Unknown';
  }

  String? _itemSubtitle(Map<String, dynamic> item) {
    if (_activeKey == 'ANIME' || _activeKey == 'MANGA') {
      final fmt = TextUtil.formatMediaFormat(item['format'] as String?);
      return fmt.isNotEmpty ? fmt : null;
    }
    if (_activeKey == 'STAFF') {
      final occ = (item['primaryOccupations'] as List?)?.cast<String>() ?? const [];
      return occ.isNotEmpty ? occ.first : null;
    }
    return null;
  }

  String? _itemImage(Map<String, dynamic> item) {
    if (_activeKey == 'ANIME' || _activeKey == 'MANGA') {
      return (item['coverImage']?['large'] ?? item['coverImage']?['medium']) as String?;
    }
    if (_activeKey == 'STUDIOS') return null;
    return (item['image']?['large'] ?? item['image']?['medium']) as String?;
  }

  @override
  Widget build(BuildContext context) {
    final items = _currentItems;
    final availableKeys = _lists.keys.toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: context.appTextMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                Icon(Icons.swap_vert_rounded, color: widget.accentColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reorder Favorites',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.appTextPrimary,
                        ),
                      ),
                      Text(
                        'Drag handle or tap ↑ to move to top',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 11,
                          color: context.appTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: context.appTextSecondary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: (_isSaving || !_hasChanges) ? null : _saveCurrent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(fontFamily: 'Overpass', fontWeight: FontWeight.w800, fontSize: 12.5),
                        ),
                ),
              ],
            ),
          ),
          if (availableKeys.length > 1)
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: availableKeys.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final key = availableKeys[index];
                  final selected = key == _activeKey;
                  final count = _lists[key]?.length ?? 0;
                  return ChoiceChip(
                    label: Text('${_labels[key]} ($count)'),
                    selected: selected,
                    onSelected: _isSaving
                        ? null
                        : (_) => setState(() {
                              _activeKey = key;
                              _hasChanges = false;
                            }),
                    selectedColor: widget.accentColor,
                    backgroundColor: context.appInputSurface,
                    labelStyle: TextStyle(
                      fontFamily: 'Overpass',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : context.appTextSecondary,
                    ),
                    side: BorderSide(color: selected ? widget.accentColor : context.appBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    showCheckmark: false,
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Divider(color: context.appBorder, height: 1),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              itemCount: items.length,
              onReorder: _onReorder,
              buildDefaultDragHandles: false,
              itemBuilder: (context, index) {
                final item = items[index];
                final id = item['id'] ?? index;
                final title = _itemTitle(item);
                final subtitle = _itemSubtitle(item);
                final imageUrl = _itemImage(item);

                return Container(
                  key: ValueKey('${_activeKey}_$id'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.appCard,
                    borderRadius: AppSpacing.borderRadius12,
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontFamily: 'Overpass',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: index < 3 ? widget.accentColor : context.appTextMuted,
                          ),
                        ),
                      ),
                      if (imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: AppNetworkImage(
                            imageUrl: imageUrl,
                            width: 38,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Overpass',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: context.appTextPrimary,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Overpass',
                                  fontSize: 10.5,
                                  color: context.appTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (index > 0)
                        IconButton(
                          tooltip: 'Move to #1',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.vertical_align_top_rounded,
                            size: 18,
                            color: context.appTextSecondary,
                          ),
                          onPressed: () => _moveToTop(index),
                        ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            size: 20,
                            color: context.appTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
