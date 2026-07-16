import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_formatter.dart';

class ScrubberBar extends StatefulWidget {
  final double positionSeconds;
  final double durationSeconds;
  final ValueChanged<double> onSeek;

  const ScrubberBar({
    super.key,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.onSeek,
  });

  @override
  State<ScrubberBar> createState() => _ScrubberBarState();
}

class _ScrubberBarState extends State<ScrubberBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.durationSeconds > 0 ? widget.durationSeconds : 1.0;
    final currentVal = (_dragValue ?? widget.positionSeconds).clamp(0.0, maxVal);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryAccent,
            inactiveTrackColor: Colors.white12,
            thumbColor: AppTheme.secondaryAccent,
            overlayColor: AppTheme.secondaryAccent.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: currentVal,
            min: 0.0,
            max: maxVal,
            onChanged: (val) {
              setState(() {
                _dragValue = val;
              });
            },
            onChangeEnd: (val) {
              setState(() {
                _dragValue = null;
              });
              widget.onSeek(val);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TimeFormatter.formatDuration(currentVal),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                '-${TimeFormatter.formatDuration(maxVal - currentVal)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
