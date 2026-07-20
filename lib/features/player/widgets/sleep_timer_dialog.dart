import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SleepTimerDialog extends StatelessWidget {
  final String? activeTimerText;
  final Function(int minutes) onSelectTimerMinutes;
  final VoidCallback onSelectEndOfChapter;
  final VoidCallback onCancelTimer;

  const SleepTimerDialog({
    super.key,
    this.activeTimerText,
    required this.onSelectTimerMinutes,
    required this.onSelectEndOfChapter,
    required this.onCancelTimer,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bedtime_rounded, color: AppTheme.secondaryAccent),
          SizedBox(width: 10),
          Text('Sleep Timer'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activeTimerText != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active: $activeTimerText', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      onCancelTimer();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Turn Off', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          _buildOption(context, '15 Minutes', () => onSelectTimerMinutes(15)),
          _buildOption(context, '30 Minutes', () => onSelectTimerMinutes(30)),
          _buildOption(context, '45 Minutes', () => onSelectTimerMinutes(45)),
          _buildOption(context, '1 Hour', () => onSelectTimerMinutes(60)),
          _buildOption(context, 'End of Chapter', () {
            onSelectEndOfChapter();
          }),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        onTap();
        Navigator.of(context).pop();
      },
    );
  }
}
