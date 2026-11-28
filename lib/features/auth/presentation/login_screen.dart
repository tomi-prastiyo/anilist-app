import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/animations/app_motion.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/yuyuyu_assets.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/image/app_network_image.dart';
import '../../../shared/widgets/mankai_cute_companion.dart';
import '../../../shared/widgets/mankai_logo_emblem.dart';
import '../../../shared/widgets/sakura_petals_overlay.dart';
import 'auth_controller.dart';
import 'oauth_webview_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final heroine = ref.watch(yuyuyuHeroineProvider);
    final isLoading = authState is AuthLoading;
    final accent = heroine.accentColor;

    return Scaffold(
      backgroundColor: YuYuYuAssets.twilightBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Deep Twilight Base Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF231339),
                  YuYuYuAssets.twilightBg,
                  Color(0xFF0A0611),
                ],
              ),
            ),
          ),

          // Atmospheric YuYuYu Top Banner Scrim
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 290,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: 0.28,
                  child: const AppNetworkImage(
                    imageUrl: YuYuYuAssets.bannerUrl,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        YuYuYuAssets.twilightBg.withValues(alpha: 0.35),
                        YuYuYuAssets.twilightBg.withValues(alpha: 0.85),
                        YuYuYuAssets.twilightBg,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Drifting Sakura Petals
          Positioned.fill(
            child: SakuraPetalsOverlay(petalColor: accent),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        MankaiLogoEmblem(
                          size: 96,
                          accentColor: accent,
                          radius: 26,
                        ),
                        Positioned(
                          right: -26,
                          top: -10,
                          child: MankaiFloatingMascot(
                            assetPath: heroine.fairyAsset,
                            accentColor: accent,
                            greetingText: heroine.cuteGreeting,
                            size: 40,
                            showGlow: false,
                          ),
                        ),
                      ],
                    ).animateEntrance(index: 0),
                    const SizedBox(height: 18),
                    const Text(
                      'Mankai',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        color: YuYuYuAssets.blossomTextPrimary,
                      ),
                    ).animateEntrance(index: 1),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: YuYuYuAssets.shinjuGold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Text(
                        'SANSHU HERO CLUB EDITION',
                        style: TextStyle(
                          fontFamily: 'Overpass',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: YuYuYuAssets.shinjuGold,
                        ),
                      ),
                    ).animateEntrance(index: 2),
                    const SizedBox(height: 12),
                    const Text(
                      'Track, share, and bloom with your\nfavorite anime and manga on AniList.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 14.5,
                        color: YuYuYuAssets.blossomTextSecondary,
                        height: 1.4,
                      ),
                    ).animateEntrance(index: 3),
                    const SizedBox(height: 28),

                    if (authState is Unauthenticated && authState.error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.statusDropped.withValues(alpha: 0.16),
                          borderRadius: AppSpacing.borderRadius12,
                          border: Border.all(
                            color: AppColors.statusDropped.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          authState.error!,
                          style: const TextStyle(
                            color: AppColors.statusDropped,
                            fontSize: 13,
                            fontFamily: 'Overpass',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    // Action Panel Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                      decoration: BoxDecoration(
                        color: YuYuYuAssets.twilightSurface.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: YuYuYuAssets.twilightBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: isLoading
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(color: accent),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Connecting to AniList...',
                                    style: TextStyle(
                                      fontFamily: 'Overpass',
                                      color: YuYuYuAssets.blossomTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                // Primary Sign In CTA
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          accent,
                                          Color.lerp(accent, const Color(0xFFEC4899), 0.45)!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withValues(alpha: 0.36),
                                          blurRadius: 14,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _openOAuthWebView,
                                      icon: const Icon(Icons.login_rounded, size: 20),
                                      label: const Text('Log In with AniList'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: accent.computeLuminance() > 0.62
                                            ? Colors.black
                                            : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        textStyle: const TextStyle(
                                          fontFamily: 'Overpass',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Secondary Register CTA
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: () => launchUrl(
                                      Uri.parse(ApiConstants.anilistSignupUrl),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: YuYuYuAssets.twilightBorder),
                                      backgroundColor: YuYuYuAssets.twilightCard.withValues(alpha: 0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      foregroundColor: YuYuYuAssets.blossomTextPrimary,
                                      textStyle: const TextStyle(
                                        fontFamily: 'Overpass',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    child: const Text('Create AniList Account'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Divider(color: YuYuYuAssets.twilightBorder, height: 1),
                                const SizedBox(height: 8),

                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      ref.read(authControllerProvider.notifier).loginAsGuest();
                                    },
                                    icon: Icon(
                                      Icons.explore_outlined,
                                      size: 16,
                                      color: accent,
                                    ),
                                    label: Text(
                                      'Continue as Guest',
                                      style: TextStyle(
                                        fontFamily: 'Overpass',
                                        color: accent,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ).animateEntrance(index: 4),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse(ApiConstants.anilistWebsiteUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: YuYuYuAssets.blossomTextMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Powered by AniList',
                            style: TextStyle(
                              fontFamily: 'Overpass',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: YuYuYuAssets.blossomTextSecondary.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
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
