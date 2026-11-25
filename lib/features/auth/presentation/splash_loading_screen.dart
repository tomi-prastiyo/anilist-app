import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/yuyuyu_assets.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/mankai_logo_emblem.dart';
import '../../../shared/widgets/sakura_petals_overlay.dart';

/// Atmospheric YuYuYu-inspired startup loading screen displayed while
/// session authentication and initial theme preferences resolve.
class SplashLoadingScreen extends ConsumerStatefulWidget {
  const SplashLoadingScreen({super.key});

  @override
  ConsumerState<SplashLoadingScreen> createState() => _SplashLoadingScreenState();
}

class _SplashLoadingScreenState extends ConsumerState<SplashLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroine = ref.watch(yuyuyuHeroineProvider);
    final accent = heroine.accentColor;

    return Scaffold(
      backgroundColor: YuYuYuAssets.twilightBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF211336),
                  YuYuYuAssets.twilightBg,
                  Color(0xFF0A0611),
                ],
              ),
            ),
          ),
          // Soft ambient blossom halo behind the emblem
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: 0.22),
                    YuYuYuAssets.shinjuGold.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SakuraPetalsOverlay(petalColor: accent),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: MankaiLogoEmblem(
                      size: 112,
                      accentColor: accent,
                      radius: 28,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Mankai',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: YuYuYuAssets.blossomTextPrimary,
                    ),
                  ),
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
                      'SANSHU HERO CLUB • ANILIST',
                      style: TextStyle(
                        fontFamily: 'Overpass',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: YuYuYuAssets.shinjuGold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 148,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: YuYuYuAssets.twilightBorder.withValues(alpha: 0.55),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Opening Hero Club chronicle...',
                    style: TextStyle(
                      fontFamily: 'Overpass',
                      fontSize: 12,
                      color: YuYuYuAssets.blossomTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
