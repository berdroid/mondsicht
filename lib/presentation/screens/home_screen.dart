import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mondsicht/application/location/location_cubit.dart';
import 'package:mondsicht/application/location/location_state.dart';
import 'package:mondsicht/application/moon/moon_cubit.dart';
import 'package:mondsicht/application/moon/moon_state.dart';
import 'package:mondsicht/domain/entities/moon_data.dart';
import 'package:mondsicht/presentation/display/moon_display.dart';
import 'package:mondsicht/presentation/info/moon_info_panel.dart';
import 'package:mondsicht/presentation/widgets/permission_message.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, locationState) {
          if (locationState is LocationPermissionDenied) {
            return const PermissionMessage();
          }

          return BlocBuilder<MoonCubit, MoonState>(
            builder: (context, moonState) {
              if (moonState is MoonDataAvailable) {
                return _MoonView(data: moonState.data);
              }
              // Loading / initial
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 1),
              );
            },
          );
        },
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
          SizedBox(
            width: screenWidth,
            height: screenWidth, // square
            child: display,
          ),
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
        SizedBox(
          width: screenHeight,
          height: screenHeight,
          child: display,
        ),
        Expanded(child: info),
      ],
    );
  }
}
