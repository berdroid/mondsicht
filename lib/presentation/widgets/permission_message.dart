import 'package:flutter/material.dart';

class PermissionMessage extends StatelessWidget {
  const PermissionMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 24),
            Text(
              'Location Access Required',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'MondSicht needs your location to calculate the moon\'s '
              'position and phase for your sky.\n\n'
              'Please grant location permission in Settings and restart the app.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
