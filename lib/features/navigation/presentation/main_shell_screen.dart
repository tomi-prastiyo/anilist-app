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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        color: context.appBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: context.isDark ? null : Colors.white,
                gradient: context.isDark
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF172334),
                          Color(0xFF121B28),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.isDark ? Colors.white.withValues(alpha: 0.09) : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppColors.brandBlue.withValues(alpha: 0.05),
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

    return Expanded(
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
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 12 : 8,
                vertical: 4,
              ),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.brandBlue.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                isSelected ? activeIcon : outlineIcon,
                key: ValueKey<bool>(isSelected),
                size: 21,
                color: isSelected ? AppColors.brandBlue : context.appTextSecondary,
              ),
            ),
            const SizedBox(height: 2),
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandBlue,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandBlue,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
