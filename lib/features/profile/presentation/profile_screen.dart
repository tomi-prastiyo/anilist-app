import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/image/app_avatar.dart';
import '../../../shared/image/app_network_image.dart';
import '../../activity/presentation/activity_screen.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../data/profile_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = ref.read(authControllerProvider);
    if (auth is! Authenticated) {
      return;
    }

    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.fetchUserProfile(auth.user.id);
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (_) {}
  }

  void _showLogoutConfirmDialog() {
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
    final userName = isAuthenticated ? auth.user.name : 'Guest User';
    final userAvatar = isAuthenticated ? auth.user.avatarUrl : null;
    final userBanner = isAuthenticated ? auth.user.bannerUrl : null;

    final stats = _userProfile?['statistics']?['anime'] as Map<String, dynamic>?;
    final count = stats?['count'] as int? ?? 0;
    final minutes = stats?['minutesWatched'] as int? ?? 0;
    final days = (minutes / (60 * 24)).toStringAsFixed(1);
    final meanScore = (stats?['meanScore'] as num?)?.toDouble() ?? 0.0;
    final scoreList = (stats?['scores'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          if (isAuthenticated) ...[
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.forum_outlined),
              tooltip: 'Activity',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ActivityScreen()),
                );
              },
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.p40),
        children: [
          // Banner & Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A5F), AppColors.darkCard],
                  ),
                ),
                child: userBanner != null
                    ? AppNetworkImage(imageUrl: userBanner, borderRadius: BorderRadius.zero)
                    : null,
              ),
              Positioned(
                bottom: -35,
                left: 20,
                child: AppAvatar(imageUrl: userAvatar, size: 70),
              ),
            ],
          ),
          const SizedBox(height: 44),

          // User details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                Text(
                  isAuthenticated ? 'AniList Member' : 'Guest Account',
                  style: const TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats Overview Cards
          if (isAuthenticated) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
              child: Row(
                children: [
                  _statCard('Total Anime', '$count', Icons.tv_rounded),
                  const SizedBox(width: 10),
                  _statCard('Days Watched', days, Icons.access_time_rounded),
                  const SizedBox(width: 10),
                  _statCard('Mean Score', meanScore > 0 ? '${meanScore.round()}%' : '-', Icons.star_rounded),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Score Distribution Chart
            if (scoreList.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.p16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: AppSpacing.borderRadius12,
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Score Distribution',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: scoreList.map((e) => (e['count'] as num).toDouble()).fold(0.0, (a, b) => a > b ? a : b) + 2,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (idx >= 0 && idx < scoreList.length) {
                                      return Text(
                                        '${scoreList[idx]['score']}',
                                        style: const TextStyle(fontSize: 10, color: AppColors.darkTextMuted),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: scoreList.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final val = (entry.value['count'] as num).toDouble();
                              return BarChartGroupData(
                                x: idx,
                                barRods: [
                                  BarChartRodData(
                                    toY: val,
                                    color: AppColors.brandBlue,
                                    width: 12,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],

          // App Settings
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.p20, vertical: 8),
            child: Text(
              'App Settings & Preferences',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: AppColors.brandBlue),
            title: const Text('Theme Mode'),
            subtitle: Text(themeMode.name.toUpperCase()),
            trailing: DropdownButton<AppThemeMode>(
              value: themeMode,
              dropdownColor: AppColors.darkSurface,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: AppThemeMode.dark, child: Text('AniList Dark')),
                DropdownMenuItem(value: AppThemeMode.amoled, child: Text('Pure AMOLED')),
                DropdownMenuItem(value: AppThemeMode.light, child: Text('Light')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                }
              },
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.explicit_outlined, color: AppColors.brandBlue),
            title: const Text('18+ Adult Content'),
            subtitle: const Text('Display mature anime & manga'),
            value: localStorage.displayAdultContent,
            activeTrackColor: AppColors.brandBlue,
            onChanged: (val) {
              setState(() => localStorage.displayAdultContent = val);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined, color: AppColors.brandBlue),
            title: const Text('Title Language'),
            subtitle: Text(localStorage.titleLanguage),
            trailing: DropdownButton<String>(
              value: localStorage.titleLanguage,
              dropdownColor: AppColors.darkSurface,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'ROMAJI', child: Text('Romaji')),
                DropdownMenuItem(value: 'ENGLISH', child: Text('English')),
                DropdownMenuItem(value: 'NATIVE', child: Text('Native')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => localStorage.titleLanguage = val);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
            child: OutlinedButton.icon(
              onPressed: isAuthenticated
                  ? _showLogoutConfirmDialog
                  : () => ref.read(authControllerProvider.notifier).logout(),
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
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.p12),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: AppSpacing.borderRadius12,
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.brandBlue),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.darkTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
