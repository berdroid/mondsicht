import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mondsicht/domain/entities/sun_data.dart';

class SunInfoPanel extends StatelessWidget {
  final SunData data;

  const SunInfoPanel({super.key, required this.data});

  /// Formats [time] as "HH:mm" for today or "E HH:mm" when on a different day.
  String _formatTime(DateTime? time, DateFormat timeFmt, DateTime today) {
    if (time == null) return '—';
    final sameDay = time.year == today.year &&
        time.month == today.month &&
        time.day == today.day;
    if (sameDay) return timeFmt.format(time);
    return '${DateFormat('E').format(time)} ${timeFmt.format(time)}';
  }

  String _formatDayLength(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.Hm();
    final today = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text('Sun', style: theme.textTheme.headlineMedium),
          ),
          const SizedBox(height: 24),
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
          _InfoRow(
            label: 'Culmination',
            value: _formatTime(data.culminationTime, timeFormat, today),
          ),
          const Divider(),
          _InfoRow(
            label: 'Culmination Azimuth',
            value: '${data.culminationAzimuth.toStringAsFixed(1)}°',
          ),
          const Divider(),
          _InfoRow(
            label: 'Culmination Elevation',
            value: '${data.culminationElevation.toStringAsFixed(1)}°',
          ),
          const Divider(),
          _InfoRow(
            label: 'Day Length',
            value: _formatDayLength(data.dayLength),
          ),
          const Divider(),
          _InfoRow(
            label: 'Sunrise',
            value: _formatTime(data.sunrise, timeFormat, today),
          ),
          const Divider(),
          _InfoRow(
            label: 'Sunset',
            value: _formatTime(data.sunset, timeFormat, today),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(vertical: 5),
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
