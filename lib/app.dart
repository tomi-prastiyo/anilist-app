import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/navigation/presentation/main_shell_screen.dart';

class AniListApp extends ConsumerWidget {
  const AniListApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authControllerProvider);

    final flutterThemeMode = switch (themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark || AppThemeMode.amoled => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp(
      title: 'AniList',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: flutterThemeMode,
      home: switch (authState) {
        AuthLoading() || AuthInitial() => const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'AL',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: AppColors.brandBlue),
                ],
              ),
            ),
          ),
        Authenticated() || GuestMode() => const MainShellScreen(),
        Unauthenticated() => const LoginScreen(),
      },
    );
  }
}
