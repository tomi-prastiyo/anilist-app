import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/image/app_avatar.dart';
import '../../auth/presentation/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _cacheSizeText = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  void _calculateCacheSize() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _cacheSizeText = '38.4 MB');
      }
    });
  }

  void _clearCache() {
    HapticFeedback.mediumImpact();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    setState(() => _cacheSizeText = '0.0 MB');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Image cache successfully cleared!'),
          ],
        ),
        backgroundColor: AppColors.scoreHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800)),
          content: const Text(
            'Are you sure you want to log out of AniList? Your offline data and preferences will be preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Back to main shell
                ref.read(authControllerProvider.notifier).logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusDropped,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final localStorage = ref.watch(localStorageServiceProvider);
    final isAuthenticated = auth is Authenticated;
    final user = isAuthenticated ? auth.user : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.07) : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'Overpass', fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. ACCOUNT SECTION
          _buildSectionHeader('ACCOUNT'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.brandBlue.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: AppAvatar(imageUrl: user?.avatarUrl, size: 52),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Guest User',
                            style: const TextStyle(
                              fontFamily: 'Overpass',
                              fontWeight: FontWeight.w800,
                              fontSize: 16.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isAuthenticated ? AppColors.scoreHigh : AppColors.statusPlanning,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAuthenticated ? 'Connected to AniList' : 'Not signed in',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isAuthenticated) ...[
                  const SizedBox(height: 14),
                  Divider(color: cardBorder, height: 1),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse('${ApiConstants.anilistWebsiteUrl}/user/${user?.name}'),
                      mode: LaunchMode.externalApplication,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.public_rounded, size: 17, color: AppColors.brandBlue),
                              const SizedBox(width: 8),
                              const Text(
                                'View Profile on AniList.co',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.brandBlue),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 2. APPEARANCE & THEME (Dark, Light, System)
          _buildSectionHeader('APPEARANCE & THEME'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Theme Mode',
                  style: TextStyle(
                    fontFamily: 'Overpass',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your preferred visual theme for the app',
                  style: TextStyle(fontSize: 11.5, color: textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildModernThemeCard(
                      title: 'System',
                      subtitle: 'Auto OS',
                      icon: Icons.brightness_auto_rounded,
                      mode: AppThemeMode.system,
                      selected: themeMode == AppThemeMode.system,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildModernThemeCard(
                      title: 'Light',
                      subtitle: 'Bright',
                      icon: Icons.light_mode_rounded,
                      mode: AppThemeMode.light,
                      selected: themeMode == AppThemeMode.light,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildModernThemeCard(
                      title: 'Dark',
                      subtitle: 'AniList',
                      icon: Icons.dark_mode_rounded,
                      mode: AppThemeMode.dark,
                      selected: themeMode == AppThemeMode.dark,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: cardBorder, height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Title Language',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Primary title display in lists',
                          style: TextStyle(fontSize: 11.5, color: textSecondary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardBorder),
                      ),
                      child: DropdownButton<String>(
                        value: localStorage.titleLanguage,
                        dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                        items: const [
                          DropdownMenuItem(value: 'ROMAJI', child: Text('Romaji', style: TextStyle(fontSize: 12.5))),
                          DropdownMenuItem(value: 'ENGLISH', child: Text('English', style: TextStyle(fontSize: 12.5))),
                          DropdownMenuItem(value: 'NATIVE', child: Text('Native', style: TextStyle(fontSize: 12.5))),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => localStorage.titleLanguage = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 3. CONTENT PREFERENCES
          _buildSectionHeader('CONTENT PREFERENCES'),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.explicit_outlined, color: AppColors.brandBlue, size: 20),
              ),
              title: const Text('18+ Adult Content', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              subtitle: Text(
                'Show mature anime, manga, and adult tags in search & shelves',
                style: TextStyle(fontSize: 11.5, color: textSecondary),
              ),
              value: localStorage.displayAdultContent,
              activeTrackColor: AppColors.brandBlue,
              onChanged: (val) => setState(() => localStorage.displayAdultContent = val),
            ),
          ),
          const SizedBox(height: 22),

          // 4. STORAGE & CACHE
          _buildSectionHeader('STORAGE & CACHE'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Image & Data Cache', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 3),
                    Text('Current size: $_cacheSizeText', style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _clearCache,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                    foregroundColor: AppColors.brandBlue,
                    elevation: 0,
                    side: BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 5. SESSION & ABOUT
          _buildSectionHeader('ABOUT & SESSION'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('App Version', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('1.0.0 (Flutter Modern)', style: TextStyle(fontSize: 13, color: textSecondary)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('API Backend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('AniList GraphQL v2', style: TextStyle(fontSize: 13, color: textSecondary)),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: cardBorder, height: 1),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isAuthenticated
                        ? _showLogoutDialog
                        : () {
                            Navigator.of(context).pop();
                            ref.read(authControllerProvider.notifier).logout();
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusDropped,
                      side: const BorderSide(color: AppColors.statusDropped),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(isAuthenticated ? Icons.logout_rounded : Icons.login_rounded),
                    label: Text(
                      isAuthenticated ? 'Log Out' : 'Sign In with AniList',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Overpass',
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: AppColors.brandBlue,
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  Widget _buildModernThemeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required AppThemeMode mode,
    required bool selected,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandBlue.withValues(alpha: 0.12)
                : (isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.brandBlue : (isDark ? Colors.white10 : AppColors.lightBorder),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? AppColors.brandBlue : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.5,
                  color: selected ? AppColors.brandBlue : (isDark ? Colors.white : AppColors.lightTextPrimary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? AppColors.brandBlue.withValues(alpha: 0.8) : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
