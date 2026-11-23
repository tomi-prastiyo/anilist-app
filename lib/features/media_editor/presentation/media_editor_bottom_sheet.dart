import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../media_list/data/media_list_repository.dart';
import '../../media_list/presentation/media_list_controller.dart';

class MediaEditorBottomSheet extends ConsumerStatefulWidget {
  final int mediaId;
  final String mediaType; // ANIME or MANGA
  final int? maxCount;
  final Map<String, dynamic>? initialEntry;
  final VoidCallback onSaved;

  const MediaEditorBottomSheet({
    super.key,
    required this.mediaId,
    required this.mediaType,
    this.maxCount,
    this.initialEntry,
    required this.onSaved,
  });

  @override
  ConsumerState<MediaEditorBottomSheet> createState() => _MediaEditorBottomSheetState();
}

class _MediaEditorBottomSheetState extends ConsumerState<MediaEditorBottomSheet> {
  late String _status;
  late double _score;
  late int _progress;
  late TextEditingController _notesController;
  bool _isSaving = false;

  final List<String> _statuses = [
    'CURRENT',
    'PLANNING',
    'COMPLETED',
    'PAUSED',
    'DROPPED',
    'REPEATING',
  ];

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _status = entry?['status'] as String? ?? 'CURRENT';
    _score = (entry?['score'] as num?)?.toDouble() ?? 0.0;
    _progress = entry?['progress'] as int? ?? 0;
    _notesController = TextEditingController(text: entry?['notes'] as String? ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatStatusLabel(String status) {
    if (widget.mediaType == 'ANIME' && status == 'CURRENT') return 'Watching';
    if (widget.mediaType == 'MANGA' && status == 'CURRENT') return 'Reading';
    return status[0] + status.substring(1).toLowerCase();
  }

  Future<void> _saveEntry() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(mediaListRepositoryProvider);
      await repo.saveMediaListEntry(
        id: widget.initialEntry?['id'] as int?,
        mediaId: widget.mediaId,
        status: _status,
        score: _score > 0 ? _score : null,
        progress: _progress,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      // Refresh list providers
      if (widget.mediaType == 'ANIME') {
        ref.read(animeListControllerProvider.notifier).loadLists();
      } else {
        ref.read(mangaListControllerProvider.notifier).loadLists();
      }

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: AppColors.statusDropped),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteEntry() async {
    final entryId = widget.initialEntry?['id'] as int?;
    if (entryId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Delete from list?'),
        content: const Text('Are you sure you want to remove this from your list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDropped,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        final repo = ref.read(mediaListRepositoryProvider);
        await repo.deleteMediaListEntry(entryId);

        if (widget.mediaType == 'ANIME') {
          ref.read(animeListControllerProvider.notifier).loadLists();
        } else {
          ref.read(mangaListControllerProvider.notifier).loadLists();
        }

        widget.onSaved();
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e'), backgroundColor: AppColors.statusDropped),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.p20,
        right: AppSpacing.p20,
        top: AppSpacing.p20,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.p20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.r24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.p16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit List Entry',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (widget.initialEntry != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusDropped),
                    onPressed: _deleteEntry,
                    tooltip: 'Delete from list',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.p16),

            // Status Selector
            const Text(
              'Status',
              style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses.map((status) {
                final isSelected = _status == status;
                return ChoiceChip(
                  label: Text(_formatStatusLabel(status)),
                  selected: isSelected,
                  selectedColor: AppColors.brandBlue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.darkTextSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _status = status);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.p20),

            // Progress Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mediaType == 'ANIME' ? 'Episodes Watched' : 'Chapters Read',
                      style: const TextStyle(fontSize: 13, color: AppColors.darkTextSecondary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_progress / ${widget.maxCount ?? '?'}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _progress > 0
                          ? () => setState(() => _progress--)
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () {
                        setState(() {
                          _progress++;
                          if (widget.maxCount != null && _progress >= widget.maxCount!) {
                            _status = 'COMPLETED';
                          }
                        });
                      },
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.p20),

            // Score Slider (0 to 100)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Score',
                  style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary, fontWeight: FontWeight.w600),
                ),
                Text(
                  _score > 0 ? '${_score.round()} / 100' : 'No score',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brandBlue),
                ),
              ],
            ),
            Slider(
              value: _score,
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: AppColors.brandBlue,
              inactiveColor: AppColors.darkBorder,
              onChanged: (val) => setState(() => _score = val),
            ),
            const SizedBox(height: AppSpacing.p16),

            // Notes
            const Text(
              'Personal Notes',
              style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Add private notes...',
                hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.darkCard,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadius8,
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.p24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadius12),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Entry', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
