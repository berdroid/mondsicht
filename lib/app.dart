import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mondsicht/application/location/location_cubit.dart';
import 'package:mondsicht/application/moon/moon_cubit.dart';
import 'package:mondsicht/data/location_repository.dart';
import 'package:mondsicht/presentation/screens/home_screen.dart';
import 'package:mondsicht/presentation/theme/app_theme.dart';

class MondSichtApp extends StatelessWidget {
  const MondSichtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => LocationCubit(LocationRepository())..start(),
        ),
        BlocProvider(
          create: (context) =>
              MoonCubit(context.read<LocationCubit>()),
        ),
      ],
      child: MaterialApp(
        title: 'MondSicht',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
