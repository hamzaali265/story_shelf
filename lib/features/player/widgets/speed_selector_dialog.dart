import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SpeedSelectorDialog extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedSelected;

  const SpeedSelectorDialog({
    super.key,
    required this.currentSpeed,
    required this.onSpeedSelected,
  });

  static const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.speed_rounded, color: AppTheme.secondaryAccent),
          SizedBox(width: 10),
          Text('Playback Speed'),
        ],
      ),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: speeds.map((speed) {
          final isSelected = (currentSpeed - speed).abs() < 0.05;
          return ChoiceChip(
            label: Text('${speed}x', style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppTheme.textPrimary,
            )),
            selected: isSelected,
            selectedColor: AppTheme.primaryAccent,
            backgroundColor: AppTheme.darkCard,
            onSelected: (_) {
              onSpeedSelected(speed);
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
