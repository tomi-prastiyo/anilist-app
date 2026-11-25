import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FavouriteKind { anime, manga, character, staff }

class _FavouriteOverride {
  final bool isFavourite;
  final DateTime updatedAt;
  final Map<String, dynamic>? itemPreview;

  const _FavouriteOverride({
    required this.isFavourite,
    required this.updatedAt,
    this.itemPreview,
  });
}

/// Short-lived in-memory sync store that bridges AniList's ~15-60s read-cache
/// lag immediately after `ToggleFavourite` succeeds on Anime, Manga,
/// Character, or Staff detail screens.
class FavouriteSyncStore {
  static const Duration _ttl = Duration(seconds: 90);
  final Map<String, _FavouriteOverride> _entries = {};

  String _key(FavouriteKind kind, int id) => '${kind.name}:$id';

  bool _isFresh(_FavouriteOverride entry) =>
      DateTime.now().difference(entry.updatedAt) < _ttl;

  void record(
    FavouriteKind kind,
    int id,
    bool isFavourite, {
    Map<String, dynamic>? itemPreview,
  }) {
    _entries[_key(kind, id)] = _FavouriteOverride(
      isFavourite: isFavourite,
      updatedAt: DateTime.now(),
      itemPreview: itemPreview,
    );
  }

  bool resolve(FavouriteKind kind, int id, bool serverValue) {
    final k = _key(kind, id);
    final entry = _entries[k];
    if (entry == null) return serverValue;
    if (!_isFresh(entry)) {
      _entries.remove(k);
      return serverValue;
    }
    return entry.isFavourite;
  }

  List<Map<String, dynamic>> applyToList(
    FavouriteKind kind,
    List<Map<String, dynamic>> items,
  ) {
    final now = DateTime.now();
    _entries.removeWhere((_, v) => now.difference(v.updatedAt) >= _ttl);

    final prefix = '${kind.name}:';
    final hiddenIds = <int>{};
    final addedPreviews = <Map<String, dynamic>>[];

    _entries.forEach((key, entry) {
      if (!key.startsWith(prefix)) return;
      final id = int.tryParse(key.substring(prefix.length));
      if (id == null) return;
      if (!entry.isFavourite) {
        hiddenIds.add(id);
      } else if (entry.itemPreview != null &&
          !items.any((it) => it['id'] == id)) {
        addedPreviews.add(entry.itemPreview!);
      }
    });

    final filtered = items
        .where((it) => !hiddenIds.contains(it['id'] as int?))
        .toList();
    return [...filtered, ...addedPreviews];
  }
}

final favouriteSyncStoreProvider = Provider<FavouriteSyncStore>((ref) {
  return FavouriteSyncStore();
});
