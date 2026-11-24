import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import 'auth_controller.dart';
import 'oauth_webview_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _openOAuthWebView() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OAuthWebViewScreen(
          onTokenReceived: (token) {
            if (mounted) {
              ref.read(authControllerProvider.notifier).loginWithToken(token);
            }
          },
        ),
      ),
    );
  }

  void _showTokenInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Enter AniList Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You can generate a personal access token under AniList Developer Settings:',
              style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => launchUrl(Uri.parse(ApiConstants.anilistDeveloperUrl), mode: LaunchMode.externalApplication),
              child: const Text(
                'Open AniList Developer Settings ↗',
                style: TextStyle(fontSize: 12, color: AppColors.brandBlue, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                hintText: 'Paste token here...',
                hintStyle: const TextStyle(color: AppColors.darkTextMuted),
                filled: true,
                fillColor: AppColors.darkCard,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadius8,
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final token = _tokenController.text.trim();
              if (token.isNotEmpty) {
                Navigator.of(context).pop();
                ref.read(authControllerProvider.notifier).loginWithToken(token);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      body: Stack(
        children: [
          // Background ambient gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F1E32),
                  AppColors.darkBackground,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // AniList Brand Icon
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.brandBlue,
                        borderRadius: AppSpacing.borderRadius24,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandBlue.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'AL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.p24),
                    const Text(
                      'AniList',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.p8),
                    const Text(
                      'Track, share, and discover\nyour favorite anime and manga.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.darkTextSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.p40),

                    if (authState is Unauthenticated && authState.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.p12),
                        margin: const EdgeInsets.only(bottom: AppSpacing.p16),
                        decoration: BoxDecoration(
                          color: AppColors.statusDropped.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.borderRadius8,
                          border: Border.all(color: AppColors.statusDropped.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          authState.error!,
                          style: const TextStyle(color: AppColors.statusDropped, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    if (isLoading) ...[
                      const CircularProgressIndicator(color: AppColors.brandBlue),
                      const SizedBox(height: AppSpacing.p16),
                      const Text(
                        'Authenticating...',
                        style: TextStyle(color: AppColors.darkTextSecondary),
                      ),
                    ] else ...[
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _openOAuthWebView,
                          icon: const Icon(Icons.login_rounded, size: 20),
                          label: const Text('Log In with AniList'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadius12),
                            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p12),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => launchUrl(Uri.parse(ApiConstants.anilistSignupUrl), mode: LaunchMode.externalApplication),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.darkBorder),
                            shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadius12),
                            foregroundColor: AppColors.darkTextPrimary,
                            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          child: const Text('Register on AniList'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p20),

                      // Manual Token Option
                      TextButton.icon(
                        onPressed: _showTokenInputDialog,
                        icon: const Icon(Icons.key_rounded, size: 16, color: AppColors.darkTextSecondary),
                        label: const Text(
                          'Enter Developer Access Token',
                          style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p12),

                      // Guest Mode
                      TextButton(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).loginAsGuest();
                        },
                        child: const Text(
                          'Continue as Guest',
                          style: TextStyle(
                            color: AppColors.brandBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
