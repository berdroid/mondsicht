import 'package:flutter/material.dart';
import 'package:mondsicht/domain/entities/location_data.dart';
import 'package:url_launcher/url_launcher.dart';

/// Thin bar pinned to the bottom of the screen showing GPS coordinates
/// and a photo credit link.
class StatusFooter extends StatelessWidget {
  final LocationData? location;

  static const String _creditLabel = 'Moon photo: Luc Viatour';
  static final Uri _creditUri = Uri.parse('https://lucnix.be/');

  const StatusFooter({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = location;

    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Location coordinates + accuracy
            Expanded(
              child: loc == null
                  ? Text(
                      'Acquiring location…',
                      style: theme.textTheme.bodySmall,
                    )
                  : Text(
                      _formatLocation(loc),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            const SizedBox(width: 8),
            // Clickable image credit
            GestureDetector(
              onTap: () => launchUrl(_creditUri,
                  mode: LaunchMode.externalApplication),
              child: Text(
                _creditLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFD4AF6A),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFFD4AF6A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLocation(LocationData loc) {
    final lat = loc.latitude;
    final lon = loc.longitude;
    final acc = loc.accuracy;

    final latStr =
        '${lat.abs().toStringAsFixed(4)}°\u202F${lat >= 0 ? 'N' : 'S'}';
    final lonStr =
        '${lon.abs().toStringAsFixed(4)}°\u202F${lon >= 0 ? 'E' : 'W'}';
    final accStr = acc > 0 ? '  ±${acc.round()}\u202Fm' : '';

    return '$latStr  $lonStr$accStr';
  }
}
