import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/navigation/presentation/main_shell_screen.dart';
import 'shared/widgets/sakura_petals_overlay.dart';

class AniListApp extends ConsumerWidget {
  const AniListApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final heroine = ref.watch(yuyuyuHeroineProvider);
    final authState = ref.watch(authControllerProvider);

    final isYuYuYu = themeMode == AppThemeMode.yuyuyu;
    final flutterThemeMode = switch (themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark || AppThemeMode.yuyuyu => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp(
      title: 'AniList',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: isYuYuYu ? AppTheme.yuyuyuTheme(heroine) : AppTheme.darkTheme,
      themeMode: flutterThemeMode,
      themeAnimationDuration: const Duration(milliseconds: 280),
      builder: (context, child) {
        if (!isYuYuYu || child == null) return child ?? const SizedBox.shrink();
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: SakuraPetalsOverlay(petalColor: heroine.accentColor),
            ),
          ],
        );
      },
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
