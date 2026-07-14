import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EmptyLibraryView extends StatelessWidget {
  final bool isScanning;
  final VoidCallback onScanTap;

  const EmptyLibraryView({
    super.key,
    required this.isScanning,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryAccent.withOpacity(0.15),
              ),
              child: const Icon(
                Icons.audio_file_rounded,
                size: 64,
                color: AppTheme.secondaryAccent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Audiobooks Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'StoryShelf automatically scans your device for .m4b audiobook files.\n\nMake sure your audiobooks are saved on internal storage or SD card, then tap Scan Device below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: isScanning ? null : onScanTap,
              icon: isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(isScanning ? 'Scanning device...' : 'Scan Device for Audiobooks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
