import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mondsicht/domain/entities/moon_data.dart';
import 'package:mondsicht/presentation/display/moon_painter.dart';

class MoonDisplay extends StatefulWidget {
  final MoonData moonData;

  const MoonDisplay({super.key, required this.moonData});

  @override
  State<MoonDisplay> createState() => _MoonDisplayState();
}

class _MoonDisplayState extends State<MoonDisplay> {
  ui.Image? _moonImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load('assets/images/full_moon.jpg');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() => _moonImage = frame.image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _moonImage;

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: image == null
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 1),
              )
            : Transform.rotate(
                angle: widget.moonData.parallacticAngle,
                child: CustomPaint(
                  painter: MoonPainter(
                    image: image,
                    phase: widget.moonData.phase,
                  ),
                ),
              ),
      ),
    );
  }
}
