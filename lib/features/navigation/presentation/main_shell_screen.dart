import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../home/presentation/home_screen.dart';
import '../../media_list/presentation/media_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../search/presentation/search_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MediaListScreen(type: 'ANIME'),
    MediaListScreen(type: 'MANGA'),
    SearchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutCubic,
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        color: context.appBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: context.isYuYuYu ? null : (context.isDark ? null : Colors.white),
                gradient: context.isDark
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: context.isYuYuYu
                            ? [
                                context.appCard,
                                context.appSurface,
                              ]
                            : const [
                                Color(0xFF172334),
                                Color(0xFF121B28),
                              ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.isDark ? context.appBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.45 : 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: context.appAccent.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.explore_outlined, Icons.explore_rounded, 'Home'),
                  _buildNavItem(1, Icons.tv_outlined, Icons.tv_rounded, 'Anime'),
                  _buildNavItem(2, Icons.menu_book_outlined, Icons.menu_book_rounded, 'Manga'),
                  _buildNavItem(3, Icons.search_rounded, Icons.search_rounded, 'Search'),
                  _buildNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = context.appAccent;

    return Expanded(
      child: Semantics(
        label: label,
        selected: isSelected,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_currentIndex != index) {
              HapticFeedback.lightImpact();
              setState(() => _currentIndex = index);
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 12 : 8,
                  vertical: 3,
                ),
                decoration: isSelected
                    ? BoxDecoration(
                        color: activeColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: AnimatedScale(
                  scale: isSelected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected ? activeIcon : outlineIcon,
                    key: ValueKey<bool>(isSelected),
                    size: 20,
                    color: isSelected ? activeColor : context.appTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Overpass',
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : context.appTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
