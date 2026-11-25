import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Shared confirmation prompt for deleting the signed-in user's activity.
Future<bool> showDeleteActivityConfirmDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.appSurface,
      title: Text(
        'Delete Activity?',
        style: TextStyle(
          fontFamily: 'Overpass',
          fontWeight: FontWeight.w800,
          color: context.appTextPrimary,
        ),
      ),
      content: Text(
        'This activity will be permanently removed from AniList.',
        style: TextStyle(
          fontFamily: 'Overpass',
          color: context.appTextSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.statusDropped,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result == true;
}
