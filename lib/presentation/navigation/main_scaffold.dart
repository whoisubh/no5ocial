import 'package:flutter/material.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/presentation/screens/accounts/accounts_screen.dart';
import 'package:no5ocial/presentation/screens/calendar/calendar_screen.dart';
import 'package:no5ocial/presentation/screens/composer/composer_screen.dart';
import 'package:no5ocial/presentation/screens/content/content_library_screen.dart';
import 'package:no5ocial/presentation/screens/home/home_screen.dart';
import 'package:no5ocial/presentation/screens/settings/settings_screen.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

class MainScaffold extends StatefulWidget {
  final AppState appState;

  const MainScaffold({super.key, required this.appState});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  void _openComposer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComposerScreen(appState: widget.appState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 860;

        final screens = [
          HomeScreen(appState: widget.appState),
          ContentLibraryScreen(appState: widget.appState),
          CalendarScreen(appState: widget.appState),
          AccountsScreen(appState: widget.appState),
          SettingsScreen(appState: widget.appState),
        ];

        final actionRequiredCount = widget.appState.actionRequiredCount;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                // Executive Desktop Sidebar
                _buildDesktopSidebar(actionRequiredCount),
                // Main Content View
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopTopBar(),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1280),
                            child: IndexedStack(
                              index: _currentIndex,
                              children: screens,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile / Compact Layout
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          floatingActionButton: _currentIndex != 1
              ? FloatingActionButton.extended(
                  onPressed: _openComposer,
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w600)),
                )
              : null,
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              backgroundColor: AppColors.surface,
              elevation: 0,
              height: 64,
              indicatorColor: AppColors.accentLight,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: [
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: actionRequiredCount > 0,
                    label: Text('$actionRequiredCount'),
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.dashboard_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: actionRequiredCount > 0,
                    label: Text('$actionRequiredCount'),
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.dashboard, color: AppColors.accent),
                  ),
                  label: 'Console',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder, color: AppColors.accent),
                  label: 'Content',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month, color: AppColors.accent),
                  label: 'Calendar',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.supervised_user_circle_outlined),
                  selectedIcon: Icon(Icons.supervised_user_circle, color: AppColors.accent),
                  label: 'Accounts',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings, color: AppColors.accent),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopSidebar(int actionRequiredCount) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo & Branding Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/logo/no5ocial.png',
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Row(
                        children: [
                          Image.asset('assets/logo/no5ocial_N.png', height: 28),
                          const SizedBox(width: 8),
                          const Text(
                            'No5ocial',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 12, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text(
                        'SHAADOW OPS • v1.0',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Primary Create Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppColors.glowShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openComposer,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Create New Post',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 8),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  title: 'Console & Queue',
                  badgeCount: actionRequiredCount,
                  isErrorBadge: true,
                ),
                _buildSidebarItem(
                  index: 1,
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder,
                  title: 'Content Library',
                ),
                _buildSidebarItem(
                  index: 2,
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  title: 'Publishing Calendar',
                ),
                _buildSidebarItem(
                  index: 3,
                  icon: Icons.supervised_user_circle_outlined,
                  activeIcon: Icons.supervised_user_circle,
                  title: 'Connected Channels',
                  badgeCount: widget.appState.accounts.length,
                ),
                _buildSidebarItem(
                  index: 4,
                  icon: Icons.tune_outlined,
                  activeIcon: Icons.tune,
                  title: 'Settings & Audit',
                ),
              ],
            ),
          ),

          // Bottom Account / Status Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/logo/no5ocial_N.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (_, _, _) => Container(
                      width: 32,
                      height: 32,
                      color: AppColors.ink,
                      child: const Center(
                        child: Text(
                          'N',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shaadow Studio',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '9 Accounts Live',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.circle, size: 8, color: AppColors.success),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    int? badgeCount,
    bool isErrorBadge = false,
  }) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? AppColors.accentLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppColors.surfaceSecondary,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 19,
                  color: isSelected ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.accent : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isErrorBadge ? AppColors.error : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isErrorBadge ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getTitleForIndex(_currentIndex),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Timezone indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  widget.appState.userTimezone,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Health status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.successBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, size: 12, color: AppColors.success),
                SizedBox(width: 4),
                Text(
                  'Systems Operational',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Publishing Operations Console';
      case 1:
        return 'Multi-Platform Content Library';
      case 2:
        return 'Scheduled Editorial Calendar';
      case 3:
        return 'Brand & Channel Registry';
      case 4:
        return 'System Configuration & Security Audit';
      default:
        return 'No5ocial Console';
    }
  }
}
