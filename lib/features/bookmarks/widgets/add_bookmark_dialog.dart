import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_formatter.dart';

class AddBookmarkDialog extends StatefulWidget {
  final double positionSeconds;
  final String chapterTitle;
  final ValueChanged<String?> onSave;

  const AddBookmarkDialog({
    super.key,
    required this.positionSeconds,
    required this.chapterTitle,
    required this.onSave,
  });

  @override
  State<AddBookmarkDialog> createState() => _AddBookmarkDialogState();
}

class _AddBookmarkDialogState extends State<AddBookmarkDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bookmark_add_rounded, color: AppTheme.secondaryAccent),
          SizedBox(width: 10),
          Text('Add Bookmark'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timestamp: ${TimeFormatter.formatDuration(widget.positionSeconds)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Chapter: ${widget.chapterTitle}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Add an optional note or quote...',
              filled: true,
              fillColor: AppTheme.darkCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            widget.onSave(_controller.text.trim().isEmpty ? null : _controller.text.trim());
            Navigator.of(context).pop();
          },
          child: const Text('Save Bookmark'),
        ),
      ],
    );
  }
}
