import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/media_progress_util.dart';
import '../../../core/utils/score_util.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../media_list/data/media_list_repository.dart';
import '../../media_list/presentation/media_list_controller.dart';

class MediaEditorBottomSheet extends ConsumerStatefulWidget {
  final int mediaId;
  final String mediaType; // ANIME or MANGA
  final int? maxCount;
  final int? maxVolumes;
  final Map<String, dynamic>? initialEntry;
  final VoidCallback onSaved;

  const MediaEditorBottomSheet({
    super.key,
    required this.mediaId,
    required this.mediaType,
    this.maxCount,
    this.maxVolumes,
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
  late int _progressVolumes;
  late int _repeat;
  late bool _isPrivate;
  Map<String, int>? _startedAt;
  Map<String, int>? _completedAt;
  late TextEditingController _notesController;
  bool _isSaving = false;
  bool _repeatIncrementedThisSession = false;
  bool _clearStartedAt = false;
  bool _clearCompletedAt = false;
  late final bool _isNewEntry;

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
    _isNewEntry = entry == null;
    _status = entry?['status'] as String? ?? 'CURRENT';
    _score = (entry?['score'] as num?)?.toDouble() ?? 0.0;
    _progress = entry?['progress'] as int? ?? 0;
    _progressVolumes = entry?['progressVolumes'] as int? ?? 0;
    _repeat = entry?['repeat'] as int? ?? 0;
    _isPrivate = entry?['private'] as bool? ?? false;
    _startedAt = MediaProgressUtil.parseFuzzyDate(entry?['startedAt']);
    _completedAt = MediaProgressUtil.parseFuzzyDate(entry?['completedAt']);
    if (_isNewEntry && _status == 'CURRENT' && _startedAt == null) {
      _startedAt = MediaProgressUtil.todayFuzzyDate();
    }
    _notesController = TextEditingController(text: entry?['notes'] as String? ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatStatusLabel(String status) {
    if (status == 'CURRENT') return widget.mediaType == 'ANIME' ? 'Watching' : 'Reading';
    if (status == 'REPEATING') return widget.mediaType == 'ANIME' ? 'Rewatching' : 'Rereading';
    return status[0] + status.substring(1).toLowerCase();
  }

  void _applyStatusTransition(String nextStatus) {
    final res = MediaProgressUtil.resolveStatusChange(
      previousStatus: _status,
      nextStatus: nextStatus,
      currentProgress: _progress,
      currentVolumes: _progressVolumes,
      currentRepeat: _repeat,
      maxCount: widget.maxCount,
      maxVolumes: widget.maxVolumes,
      startedAt: _startedAt,
      completedAt: _completedAt,
      isManga: widget.mediaType == 'MANGA',
      hasIncrementedRepeatThisSession: _repeatIncrementedThisSession,
      isNewEntry: _isNewEntry,
    );
    _status = res.status;
    _progress = res.progress;
    _progressVolumes = res.progressVolumes;
    _repeat = res.repeat;
    _startedAt = res.startedAt;
    _completedAt = res.completedAt;
    if (_startedAt != null) _clearStartedAt = false;
    if (_completedAt != null) _clearCompletedAt = false;
    if (res.repeatIncremented) {
      _repeatIncrementedThisSession = true;
    }
  }

  void _applyProgressChange(int nextProgress) {
    _progress = nextProgress;
    if (widget.maxCount != null && _progress >= widget.maxCount!) {
      _applyStatusTransition('COMPLETED');
    } else if (_progress > 0 &&
        (_status == 'PLANNING' || _status == 'PAUSED' || _status == 'DROPPED')) {
      _applyStatusTransition('CURRENT');
    } else if (_status == 'COMPLETED' &&
        widget.maxCount != null &&
        _progress < widget.maxCount!) {
      _applyStatusTransition('CURRENT');
    } else if (_progress > 0 && _startedAt == null && !_clearStartedAt) {
      _startedAt = MediaProgressUtil.todayFuzzyDate();
    }
  }

  void _applyVolumeChange(int nextVolumes) {
    _progressVolumes = nextVolumes;
    if (_progressVolumes > 0 &&
        (_status == 'PLANNING' || _status == 'PAUSED' || _status == 'DROPPED')) {
      _applyStatusTransition('CURRENT');
    } else if (_progressVolumes > 0 && _startedAt == null && !_clearStartedAt) {
      _startedAt = MediaProgressUtil.todayFuzzyDate();
    }
  }

  double _maxScoreForFormat(String format) {
    switch (format) {
      case 'POINT_10_DECIMAL':
      case 'POINT_10':
        return 10.0;
      case 'POINT_5':
        return 5.0;
      case 'POINT_3':
        return 3.0;
      case 'POINT_100':
      default:
        return 100.0;
    }
  }

  double _stepForFormat(String format) {
    switch (format) {
      case 'POINT_10_DECIMAL':
        return 0.5;
      case 'POINT_10':
      case 'POINT_5':
      case 'POINT_3':
      case 'POINT_100':
      default:
        return 1.0;
    }
  }

  double _normalizedScoreValue(String format, double raw) {
    final max = _maxScoreForFormat(format);
    if (raw <= max) return raw;
    // If raw is stored in 0..100 scale, scale down to user's format cleanly
    return ((raw / 100.0) * max).clamp(0.0, max);
  }

  Future<void> _pickFuzzyDate({required bool isStart}) async {
    final current = isStart ? _startedAt : _completedAt;
    final now = DateTime.now();
    final initial = current != null && current['year'] != null
        ? DateTime(
            current['year']!,
            current['month'] ?? 1,
            current['day'] ?? 1,
          )
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      setState(() {
        final mapped = {'year': picked.year, 'month': picked.month, 'day': picked.day};
        if (isStart) {
          _startedAt = mapped;
          _clearStartedAt = false;
        } else {
          _completedAt = mapped;
          _clearCompletedAt = false;
        }
      });
    }
  }

  Future<void> _showNumberInputDialog({
    required String title,
    required int currentValue,
    int? maxValue,
    required ValueChanged<int> onConfirm,
  }) async {
    final controller = TextEditingController(text: '$currentValue');
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Set $title',
          style: AppTypography.style(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.appTextPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: maxValue != null ? '0 – $maxValue' : 'Enter number',
            suffixText: maxValue != null ? '/ $maxValue' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: context.appTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null) {
                final clamped = maxValue != null ? parsed.clamp(0, maxValue) : parsed.clamp(0, 99999);
                Navigator.of(dialogContext).pop(clamped);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.appAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && mounted) {
      onConfirm(result);
    }
  }

  Future<void> _saveEntry() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final repo = ref.read(mediaListRepositoryProvider);
      await repo.saveMediaListEntry(
        id: widget.initialEntry?['id'] as int?,
        mediaId: widget.mediaId,
        status: _status,
        score: _score > 0 ? _score : 0.0,
        progress: _progress,
        progressVolumes: widget.mediaType == 'MANGA' ? _progressVolumes : null,
        repeat: _repeat,
        isPrivate: _isPrivate,
        startedAt: _startedAt,
        completedAt: _completedAt,
        clearStartedAt: _clearStartedAt,
        clearCompletedAt: _clearCompletedAt,
        notes: _notesController.text.trim(),
      );

      if (widget.mediaType == 'ANIME') {
        ref.read(animeListControllerProvider.notifier).loadLists();
      } else {
        ref.read(mangaListControllerProvider.notifier).loadLists();
      }

      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Saved to ${_formatStatusLabel(_status)}'),
          duration: const Duration(seconds: 2),
        ),
      );
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
        backgroundColor: context.appSurface,
        title: const Text('Delete from list?'),
        content: const Text('Are you sure you want to remove this from your list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: context.appTextSecondary)),
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
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
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
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Removed from list'),
            duration: Duration(seconds: 2),
          ),
        );
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
    final auth = ref.watch(authControllerProvider);
    final scoreFormat = auth is Authenticated ? auth.user.scoreFormat : 'POINT_100';
    final accent = context.appAccent;
    final maxScore = _maxScoreForFormat(scoreFormat);
    final step = _stepForFormat(scoreFormat);
    final displayScore = _normalizedScoreValue(scoreFormat, _score);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.p20,
        right: AppSpacing.p20,
        top: AppSpacing.p16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.p20,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.r24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.p12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit List Entry',
                  style: AppTypography.style(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.appTextPrimary,
                  ),
                ),
                if (widget.initialEntry != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusDropped),
                    onPressed: _deleteEntry,
                    tooltip: 'Delete from list',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.p12),

            // Status Selector
            Text(
              'Status',
              style: AppTypography.style(
                fontSize: 12.5,
                color: context.appTextSecondary,
                fontWeight: FontWeight.w700,
              ),
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
                  selectedColor: accent,
                  backgroundColor: context.appInputSurface,
                  labelStyle: AppTypography.style(
                    color: isSelected
                        ? (accent.computeLuminance() > 0.55 ? Colors.black : Colors.white)
                        : context.appTextSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _applyStatusTransition(status);
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.p16),

            // Progress, Volumes (Manga) & Rewatch Steppers
            Row(
              children: [
                Expanded(
                  child: _buildStepperCard(
                    title: widget.mediaType == 'ANIME' ? 'Episodes' : 'Chapters',
                    valueText: '$_progress / ${widget.maxCount ?? '?'}',
                    onMinus: _progress > 0
                        ? () => setState(() => _applyProgressChange(_progress - 1))
                        : null,
                    onPlus: (widget.maxCount != null && _progress >= widget.maxCount!)
                        ? null
                        : () => setState(() => _applyProgressChange(_progress + 1)),
                    onTapValue: () => _showNumberInputDialog(
                      title: widget.mediaType == 'ANIME' ? 'Episodes' : 'Chapters',
                      currentValue: _progress,
                      maxValue: widget.maxCount,
                      onConfirm: (val) => setState(() => _applyProgressChange(val)),
                    ),
                    onMax: (widget.maxCount != null && _progress < widget.maxCount!)
                        ? () => setState(() => _applyProgressChange(widget.maxCount!))
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: widget.mediaType == 'MANGA'
                      ? _buildStepperCard(
                          title: 'Volumes',
                          valueText: '$_progressVolumes / ${widget.maxVolumes ?? '?'}',
                          onMinus: _progressVolumes > 0
                              ? () => setState(() => _applyVolumeChange(_progressVolumes - 1))
                              : null,
                          onPlus: (widget.maxVolumes != null &&
                                  _progressVolumes >= widget.maxVolumes!)
                              ? null
                              : () => setState(() => _applyVolumeChange(_progressVolumes + 1)),
                          onTapValue: () => _showNumberInputDialog(
                            title: 'Volumes',
                            currentValue: _progressVolumes,
                            maxValue: widget.maxVolumes,
                            onConfirm: (val) => setState(() => _applyVolumeChange(val)),
                          ),
                          onMax: (widget.maxVolumes != null &&
                                  _progressVolumes < widget.maxVolumes!)
                              ? () => setState(() => _applyVolumeChange(widget.maxVolumes!))
                              : null,
                        )
                      : _buildStepperCard(
                          title: 'Rewatches',
                          valueText: '$_repeat',
                          onMinus: _repeat > 0 ? () => setState(() => _repeat--) : null,
                          onPlus: () => setState(() => _repeat++),
                          onTapValue: () => _showNumberInputDialog(
                            title: 'Rewatches',
                            currentValue: _repeat,
                            onConfirm: (val) => setState(() => _repeat = val),
                          ),
                        ),
                ),
              ],
            ),
            if (widget.mediaType == 'MANGA') ...[
              const SizedBox(height: 10),
              _buildStepperCard(
                title: 'Rereads',
                valueText: '$_repeat',
                onMinus: _repeat > 0 ? () => setState(() => _repeat--) : null,
                onPlus: () => setState(() => _repeat++),
                onTapValue: () => _showNumberInputDialog(
                  title: 'Rereads',
                  currentValue: _repeat,
                  onConfirm: (val) => setState(() => _repeat = val),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.p16),

            // Score Precision Editor (Slider + Stepper)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score',
                  style: AppTypography.style(
                    fontSize: 12.5,
                    color: context.appTextSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      onPressed: displayScore > 0
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _score = (displayScore - step).clamp(0.0, maxScore);
                              });
                            }
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      displayScore > 0 ? ScoreUtil.formatScore(displayScore, format: scoreFormat) : 'No Score',
                      style: AppTypography.style(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                      ),
                      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      onPressed: displayScore < maxScore
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _score = (displayScore + step).clamp(0.0, maxScore);
                              });
                            }
                          : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ],
            ),
            Slider(
              value: displayScore,
              min: 0,
              max: maxScore,
              divisions: (maxScore / step).round(),
              activeColor: accent,
              inactiveColor: context.appBorder,
              onChanged: (val) => setState(() => _score = val),
            ),
            const SizedBox(height: AppSpacing.p8),

            // Start & Finish Dates
            Row(
              children: [
                Expanded(
                  child: _buildDateTile(
                    label: 'Start Date',
                    date: _startedAt,
                    onTap: () => _pickFuzzyDate(isStart: true),
                    onClear: _startedAt != null
                        ? () => setState(() {
                              _startedAt = null;
                              _clearStartedAt = true;
                            })
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDateTile(
                    label: 'Finish Date',
                    date: _completedAt,
                    onTap: () => _pickFuzzyDate(isStart: false),
                    onClear: _completedAt != null
                        ? () => setState(() {
                              _completedAt = null;
                              _clearCompletedAt = true;
                            })
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.p12),

            // Notes
            Text(
              'Personal Notes',
              style: AppTypography.style(
                fontSize: 12.5,
                color: context.appTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              style: AppTypography.style(fontSize: 13, color: context.appTextPrimary),
              decoration: InputDecoration(
                hintText: 'Add personal notes...',
                hintStyle: AppTypography.style(color: context.appTextMuted, fontSize: 12.5),
                filled: true,
                fillColor: context.appCard,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadius8,
                  borderSide: BorderSide(color: context.appBorder),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),

            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Private Entry',
                style: AppTypography.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appTextPrimary,
                ),
              ),
              subtitle: Text(
                'Hide from public profile & friends feed',
                style: AppTypography.style(fontSize: 11, color: context.appTextSecondary),
              ),
              value: _isPrivate,
              activeTrackColor: accent,
              onChanged: (v) => setState(() => _isPrivate = v),
            ),
            const SizedBox(height: AppSpacing.p12),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: accent.computeLuminance() > 0.55 ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadius12),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent.computeLuminance() > 0.55 ? Colors.black : Colors.white,
                        ),
                      )
                    : Text(
                        'Save Entry',
                        style: AppTypography.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: accent.computeLuminance() > 0.55 ? Colors.black : Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperCard({
    required String title,
    required String valueText,
    VoidCallback? onMinus,
    VoidCallback? onPlus,
    VoidCallback? onTapValue,
    VoidCallback? onMax,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.appInputSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.style(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.appTextSecondary,
                ),
              ),
              if (onMax != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onMax();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.appAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Max',
                      style: AppTypography.style(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: context.appAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: InkWell(
                  onTap: onTapValue,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            valueText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.style(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: context.appTextPrimary,
                              decoration: onTapValue != null
                                  ? TextDecoration.underline
                                  : null,
                              decorationColor: context.appTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(34, 34),
                      padding: EdgeInsets.zero,
                    ),
                    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                    padding: EdgeInsets.zero,
                    iconSize: 17,
                    onPressed: onMinus,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(34, 34),
                      padding: EdgeInsets.zero,
                    ),
                    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                    padding: EdgeInsets.zero,
                    iconSize: 17,
                    onPressed: onPlus,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required Map<String, int>? date,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final formatted = date != null ? DateUtil.formatFuzzyDate(date) : 'Not set';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: context.appInputSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 13.5, color: context.appAccent),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.style(fontSize: 10, color: context.appTextMuted, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    formatted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.style(fontSize: 12, color: context.appTextPrimary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded, size: 15, color: context.appTextMuted),
              ),
          ],
        ),
      ),
    );
  }
}
