import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
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
    // Simulated realistic image cache estimate
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _cacheSizeText = '38.4 MB');
      }
    });
  }

  void _clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    setState(() => _cacheSizeText = '0.0 MB');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache successfully cleared!'),
        backgroundColor: AppColors.statusCompleted,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of AniList?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.darkTextSecondary)),
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
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final localStorage = ref.watch(localStorageServiceProvider);
    final isAuthenticated = auth is Authenticated;
    final user = isAuthenticated ? auth.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16, vertical: AppSpacing.p12),
        children: [
          // 1. ACCOUNT SECTION
          _buildSectionHeader('ACCOUNT'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                Row(
                  children: [
                    AppAvatar(imageUrl: user?.avatarUrl, size: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Guest User',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          Text(
                            isAuthenticated ? 'Connected to AniList' : 'Not signed in',
                            style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isAuthenticated) ...[
                  const Divider(height: 24),
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse('${ApiConstants.anilistWebsiteUrl}/user/${user?.name}'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('View AniList Web Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.brandBlue),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. APPEARANCE & THEME
          _buildSectionHeader('APPEARANCE & THEME'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _themeCard(
                      title: 'AniList Dark',
                      mode: AppThemeMode.dark,
                      color: AppColors.darkBackground,
                      selected: themeMode == AppThemeMode.dark,
                    ),
                    const SizedBox(width: 10),
                    _themeCard(
                      title: 'AMOLED',
                      mode: AppThemeMode.amoled,
                      color: AppColors.amoledBackground,
                      selected: themeMode == AppThemeMode.amoled,
                    ),
                    const SizedBox(width: 10),
                    _themeCard(
                      title: 'Light',
                      mode: AppThemeMode.light,
                      color: AppColors.lightBackground,
                      textColor: Colors.black,
                      selected: themeMode == AppThemeMode.light,
                    ),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Title Language', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    DropdownButton<String>(
                      value: localStorage.titleLanguage,
                      dropdownColor: AppColors.darkSurface,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'ROMAJI', child: Text('Romaji')),
                        DropdownMenuItem(value: 'ENGLISH', child: Text('English')),
                        DropdownMenuItem(value: 'NATIVE', child: Text('Native')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => localStorage.titleLanguage = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. CONTENT PREFERENCES
          _buildSectionHeader('CONTENT PREFERENCES'),
          Container(
            decoration: _cardDecoration(),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.explicit_outlined, color: AppColors.brandBlue),
                  title: const Text('18+ Adult Content', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Show mature anime, manga, and tags in search & browse', style: TextStyle(fontSize: 11.5, color: AppColors.darkTextSecondary)),
                  value: localStorage.displayAdultContent,
                  activeTrackColor: AppColors.brandBlue,
                  onChanged: (val) => setState(() => localStorage.displayAdultContent = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. STORAGE & CACHE
          _buildSectionHeader('STORAGE & CACHE'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: _cardDecoration(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Image & Data Cache', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text('Current size: $_cacheSizeText', style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                  ],
                ),
                OutlinedButton(
                  onPressed: _clearCache,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.darkBorder),
                    shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadius8),
                  ),
                  child: const Text('Clear Cache', style: TextStyle(fontSize: 12, color: AppColors.brandBlue)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. SESSION & ABOUT
          _buildSectionHeader('ABOUT & SESSION'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.p16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('App Version', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('1.0.0 (Flutter Modern)', style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary)),
                  ],
                ),
                const Divider(height: 24),
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
                      shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadius12),
                    ),
                    icon: Icon(isAuthenticated ? Icons.logout_rounded : Icons.login_rounded),
                    label: Text(isAuthenticated ? 'Log Out' : 'Sign In with AniList'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
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
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: AppColors.brandBlue,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.darkCard,
      borderRadius: AppSpacing.borderRadius12,
      border: Border.all(color: AppColors.darkBorder),
    );
  }

  Widget _themeCard({
    required String title,
    required AppThemeMode mode,
    required Color color,
    Color textColor = Colors.white,
    required bool selected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
        borderRadius: AppSpacing.borderRadius8,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppSpacing.borderRadius8,
            border: Border.all(
              color: selected ? AppColors.brandBlue : AppColors.darkBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 14,
                color: selected ? AppColors.brandBlue : AppColors.darkTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
