import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mondsicht/domain/entities/moon_data.dart';

class MoonInfoPanel extends StatelessWidget {
  final MoonData data;

  const MoonInfoPanel({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.Hm();
    final dateFormat = DateFormat.yMMMd();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase name
          Center(
            child: Text(
              '${_phaseEmoji(data.phase)}  ${data.phaseName}',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Illumination
          _InfoRow(
            label: 'Illumination',
            value: '${(data.illumination * 100).round()} %',
          ),
          const Divider(),

          // Position
          _InfoRow(
            label: 'Azimuth',
            value: '${data.azimuth.toStringAsFixed(1)}°',
          ),
          const Divider(),
          _InfoRow(
            label: 'Elevation',
            value: '${data.elevation.toStringAsFixed(1)}°',
          ),
          const Divider(),

          // Rise / Set
          _InfoRow(
            label: 'Moonrise',
            value: data.moonRise != null
                ? timeFormat.format(data.moonRise!)
                : '—',
          ),
          const Divider(),
          _InfoRow(
            label: 'Moonset',
            value: data.moonSet != null
                ? timeFormat.format(data.moonSet!)
                : '—',
          ),
          const Divider(),

          // Upcoming events
          _InfoRow(
            label: 'Next New Moon',
            value: dateFormat.format(data.nextNewMoon),
          ),
          const Divider(),
          _InfoRow(
            label: 'Next Full Moon',
            value: dateFormat.format(data.nextFullMoon),
          ),
        ],
      ),
    );
  }

  String _phaseEmoji(double phase) {
    if (phase < 0.0625 || phase >= 0.9375) return '🌑';
    if (phase < 0.1875) return '🌒';
    if (phase < 0.3125) return '🌓';
    if (phase < 0.4375) return '🌔';
    if (phase < 0.5625) return '🌕';
    if (phase < 0.6875) return '🌖';
    if (phase < 0.8125) return '🌗';
    return '🌘';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
