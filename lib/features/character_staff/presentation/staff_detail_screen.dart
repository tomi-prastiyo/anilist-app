import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/text_util.dart';
import '../../../shared/feedback/error_view.dart';
import '../../../shared/image/app_avatar.dart';
import '../../../shared/image/app_network_image.dart';
import '../data/character_staff_repository.dart';

class StaffDetailScreen extends ConsumerStatefulWidget {
  final int staffId;

  const StaffDetailScreen({super.key, required this.staffId});

  @override
  ConsumerState<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends ConsumerState<StaffDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;
  bool _isFavourite = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(characterStaffRepositoryProvider);
      final staff = await repo.fetchStaff(widget.staffId);
      setState(() {
        _data = staff;
        _isFavourite = staff['isFavourite'] as bool? ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFav() async {
    setState(() => _isFavourite = !_isFavourite);
    try {
      final repo = ref.read(characterStaffRepositoryProvider);
      await repo.toggleFavourite(staffId: widget.staffId);
    } catch (e) {
      setState(() => _isFavourite = !_isFavourite);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.brandBlue)));
    }
    if (_error != null) {
      return Scaffold(appBar: AppBar(), body: ErrorView(message: _error!, onRetry: _load));
    }

    final name = _data!['name']?['userPreferred'] ?? _data!['name']?['full'] ?? 'Staff';
    final nativeName = _data!['name']?['native'] as String?;
    final imageUrl = _data!['image']?['large'] as String?;
    final description = TextUtil.stripHtml(_data!['description'] as String?);
    final occupations = (_data!['primaryOccupations'] as List?)?.join(', ');
    final charMediaEdges = (_data!['characterMedia']?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: Icon(
              _isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavourite ? AppColors.favoritePink : null,
            ),
            onPressed: _toggleFav,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.p16),
        children: [
          Center(
            child: Column(
              children: [
                AppNetworkImage(
                  imageUrl: imageUrl,
                  width: 140,
                  height: 190,
                  borderRadius: AppSpacing.borderRadius16,
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                if (nativeName != null) ...[
                  const SizedBox(height: 4),
                  Text(nativeName, style: const TextStyle(fontSize: 14, color: AppColors.darkTextSecondary)),
                ],
                if (occupations != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    occupations,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.brandBlue, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (description.isNotEmpty) ...[
            const Text(
              'About',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            MarkdownBody(
              data: description,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: const TextStyle(fontSize: 13.5, color: AppColors.darkTextSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (charMediaEdges.isNotEmpty) ...[
            const Text(
              'Roles & Characters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...charMediaEdges.map((edge) {
              final media = edge['node'] as Map<String, dynamic>?;
              final characters = (edge['characters'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final character = characters.isNotEmpty ? characters.first : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: AppSpacing.borderRadius8,
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    if (character != null)
                      AppAvatar(imageUrl: character['image']?['medium'] as String?, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (character != null)
                            Text(
                              character['name']?['userPreferred'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            media?['title']?['userPreferred'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    AppNetworkImage(
                      imageUrl: media?['coverImage']?['medium'] as String?,
                      width: 40,
                      height: 55,
                      borderRadius: AppSpacing.borderRadius4,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
