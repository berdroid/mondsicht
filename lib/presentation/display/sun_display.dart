import 'dart:async';

import 'package:flutter/material.dart';

class SunDisplay extends StatefulWidget {
  const SunDisplay({super.key});

  @override
  State<SunDisplay> createState() => _SunDisplayState();
}

class _SunDisplayState extends State<SunDisplay> {
  static const _imageUrl = 'https://soho.nascom.nasa.gov/data/realtime/hmi_igr/1024/latest.jpg';
  static const _imageProvider = NetworkImage(_imageUrl);

  Timer? _timer;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    // Evict cached image and reload once per hour.
    _timer = Timer.periodic(const Duration(hours: 1), (_) {
      imageCache.evict(_imageProvider);
      setState(() => _generation++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: Image.network(
          _imageUrl,
          key: ValueKey(_generation),
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 1)),
          errorBuilder: (_, _, _) => const Center(child: Icon(Icons.cloud_off_outlined, size: 48)),
        ),
      ),
    );
  }
}
