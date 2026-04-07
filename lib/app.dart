// lib/app.dart
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/home/home_screen.dart';

class AnaApp extends ConsumerWidget {
  const AnaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          title: 'AnaApp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(dynamicScheme: lightDynamic),
          darkTheme: AppTheme.dark(dynamicScheme: darkDynamic),
          themeMode: ThemeMode.system,
          home: userAsync.when(
            data: (user) =>
                user == null ? const OnboardingScreen() : const HomeScreen(),
            loading: () =>
                const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (_, __) => const OnboardingScreen(),
          ),
        );
      },
    );
  }
}
