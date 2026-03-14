import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mondsicht/application/location/location_cubit.dart';
import 'package:mondsicht/application/location/location_state.dart';
import 'package:mondsicht/application/moon/moon_cubit.dart';
import 'package:mondsicht/application/moon/moon_state.dart';
import 'package:mondsicht/domain/entities/moon_data.dart';
import 'package:mondsicht/presentation/display/moon_display.dart';
import 'package:mondsicht/presentation/display/moon_painter.dart';
import 'package:mondsicht/presentation/info/moon_info_panel.dart';
import 'package:mondsicht/presentation/widgets/permission_message.dart';
import 'package:mondsicht/presentation/widgets/status_footer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: safeArea.top,
          left: safeArea.left,
          right: safeArea.right,
          bottom: safeArea.bottom,
        ),
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<LocationCubit, LocationState>(
                builder: (context, locationState) {
                  if (locationState is LocationPermissionDenied) {
                    return const PermissionMessage();
                  }

                  return BlocBuilder<MoonCubit, MoonState>(
                    builder: (context, moonState) {
                      if (moonState is MoonDataAvailable) {
                        return _MoonView(data: moonState.data);
                      }
                      return const _SplashScreen();
                    },
                  );
                },
              ),
            ),
            // Pinned footer — always visible at the very bottom.
            BlocBuilder<LocationCubit, LocationState>(
              builder: (context, locationState) {
                final location = locationState is LocationAvailable ? locationState.location : null;
                return StatusFooter(location: location);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  ui.Image? _moonImage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 8), vsync: this)..repeat();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load('assets/images/full_moon.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _moonImage = frame.image);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _moonImage;
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.65,
        child: AspectRatio(
          aspectRatio: 1,
          child: image == null
              ? const SizedBox.shrink()
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: MoonPainter(image: image, phase: _controller.value),
                  ),
                ),
        ),
      ),
    );
  }
}

class _MoonView extends StatelessWidget {
  final MoonData data;

  const _MoonView({required this.data});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final display = MoonDisplay(moonData: data);
        final info = MoonInfoPanel(data: data);

        if (orientation == Orientation.portrait) {
          return _PortraitLayout(display: display, info: info);
        } else {
          return _LandscapeLayout(display: display, info: info);
        }
      },
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  final Widget display;
  final Widget info;

  const _PortraitLayout({required this.display, required this.info});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(width: screenWidth, height: screenWidth, child: display),
          info,
        ],
      ),
    );
  }
}

class _LandscapeLayout extends StatelessWidget {
  final Widget display;
  final Widget info;

  const _LandscapeLayout({required this.display, required this.info});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Row(
      children: [
        SizedBox(width: screenHeight, height: screenHeight, child: display),
        Expanded(child: info),
      ],
    );
  }
}
