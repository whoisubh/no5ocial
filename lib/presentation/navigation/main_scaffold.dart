import 'package:flutter/material.dart';
import 'package:no5ocial/core/extensions/l10n_extension.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/l10n/app_localizations.dart';
import 'package:no5ocial/presentation/screens/accounts/accounts_screen.dart';
import 'package:no5ocial/presentation/screens/calendar/calendar_screen.dart';
import 'package:no5ocial/presentation/screens/composer/composer_screen.dart';
import 'package:no5ocial/presentation/screens/content/content_library_screen.dart';
import 'package:no5ocial/presentation/screens/home/home_screen.dart';
import 'package:no5ocial/presentation/screens/settings/settings_screen.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/app_sheets.dart';
import 'package:no5ocial/presentation/widgets/dialogs/entity_dialogs.dart';

class MainScaffold extends StatefulWidget {
  final AppState appState;
  final int initialIndex;

  const MainScaffold({
    super.key,
    required this.appState,
    this.initialIndex = 0,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _openComposer() {
    if (widget.appState.accounts.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please integrate at least one social channel first before creating a post.',
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Connect Channel',
            onPressed: () => _onTabSelected(3),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComposerScreen(appState: widget.appState),
      ),
    );
  }

  void _openScheduleComposer() {
    if (widget.appState.accounts.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please integrate at least one social channel first before creating a post.',
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Connect Channel',
            onPressed: () => _onTabSelected(3),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComposerScreen(
          appState: widget.appState,
          initialScheduledDate: DateTime.now().add(const Duration(hours: 2)),
        ),
      ),
    );
  }

  void _showChannelsFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Channels & Groups',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_link, color: Colors.white, size: 20),
                ),
                title: const Text('Integrate Channel', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Link Instagram, YouTube, X, or LinkedIn profile', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(bCtx).pop();
                  EntityDialogs.showConnectChannelDialog(context, widget.appState);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_rounded, color: Colors.white, size: 20),
                ),
                title: const Text('Create Channel Group', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Bundle multiple profiles into a unified group', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(bCtx).pop();
                  EntityDialogs.showCreateGroupDialog(context, widget.appState);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business_rounded, color: AppColors.accent, size: 20),
                ),
                title: const Text('Register Company', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Add a new brand workspace portfolio', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(bCtx).pop();
                  EntityDialogs.showRegisterCompanyDialog(context, widget.appState);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0: // Overview
      case 1: // Content
        return FloatingActionButton.extended(
          onPressed: _openComposer,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Post',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      case 2: // Schedule
        return FloatingActionButton.extended(
          onPressed: _openScheduleComposer,
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Schedule',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      case 3: // Channels
        return FloatingActionButton.extended(
          onPressed: () => _showChannelsFabMenu(context),
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'New Channel / Group',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        // Strict Active Auth Guard: unauthenticated sessions cannot access dashboard
        if (!widget.appState.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
          });
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Trigger welcome workspace dialog upon newly registered organization
        if (widget.appState.shouldShowWelcomeDialog) {
          widget.appState.shouldShowWelcomeDialog = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final brand = widget.appState.brands.isNotEmpty
                ? widget.appState.brands.first.name
                : 'Workspace';
            AppSheets.showWelcomeWorkspaceDialog(
              context,
              brandName: brand,
              onConnectChannels: () {
                _onTabSelected(3); // Navigate to channels tab
              },
            );
          });
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 860;
        final l10n = context.l10n;

        final screens = [
          HomeScreen(
            appState: widget.appState,
            onNavigate: _onTabSelected,
          ),
          ContentLibraryScreen(appState: widget.appState),
          CalendarScreen(appState: widget.appState),
          AccountsScreen(appState: widget.appState),
          SettingsScreen(appState: widget.appState),
        ];

        final actionRequiredCount = widget.appState.actionRequiredCount;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.bgOf(context),
            body: Row(
              children: [
                // Executive Desktop Sidebar
                _buildDesktopSidebar(actionRequiredCount, l10n),
                // Main Content View
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopTopBar(l10n),
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
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: screens,
          ),
          floatingActionButton: _buildFloatingActionButton(),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              border: Border(
                top: BorderSide(color: AppColors.borderOf(context), width: 1),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              backgroundColor: AppColors.surfaceOf(context),
              elevation: 0,
              height: 64,
              indicatorColor: widget.appState.isDarkMode ? const Color(0xFF233560) : AppColors.accentLight,
              onDestinationSelected: _onTabSelected,
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
                  label: 'Overview',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.folder_outlined),
                  selectedIcon: const Icon(Icons.folder, color: AppColors.accent),
                  label: 'Content',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  selectedIcon: const Icon(
                    Icons.calendar_month,
                    color: AppColors.accent,
                  ),
                  label: 'Schedule',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.supervised_user_circle_outlined),
                  selectedIcon: const Icon(
                    Icons.supervised_user_circle,
                    color: AppColors.accent,
                  ),
                  label: 'Channels',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings, color: AppColors.accent),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopSidebar(int actionRequiredCount, AppLocalizations l10n) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        border: Border(right: BorderSide(color: AppColors.borderOf(context), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo & Branding Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      widget.appState.isDarkMode
                          ? 'assets/logo/no5ocial_white.png'
                          : 'assets/logo/no5ocial.png',
                      height: 34,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, _, _) => Row(
                        children: [
                          Image.asset('assets/logo/no5ocial_N.png', height: 28),
                          const SizedBox(width: 8),
                          Text(
                            'no5ocial',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: AppColors.textOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          l10n.btnCreatePost,
                          style: const TextStyle(
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
                  title: l10n.navQueue,
                  badgeCount: actionRequiredCount,
                  isErrorBadge: true,
                ),
                _buildSidebarItem(
                  index: 1,
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder,
                  title: l10n.navContent,
                ),
                _buildSidebarItem(
                  index: 2,
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  title: l10n.navCalendar,
                ),
                _buildSidebarItem(
                  index: 3,
                  icon: Icons.supervised_user_circle_outlined,
                  activeIcon: Icons.supervised_user_circle,
                  title: l10n.navChannels,
                  badgeCount: widget.appState.accounts.length,
                ),
                _buildSidebarItem(
                  index: 4,
                  icon: Icons.tune_outlined,
                  activeIcon: Icons.tune,
                  title: l10n.navSettings,
                ),
              ],
            ),
          ),

          // Bottom Account / Status Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow,
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    'assets/logo/no5ocial_N.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.ink,
                      child: const Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appState.brands.isNotEmpty
                            ? '${widget.appState.brands.first.name} Workspace'
                            : l10n.growthWorkspace,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.channelsConnected(widget.appState.accounts.length),
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.appState.accounts.isNotEmpty ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.circle,
                  size: 8,
                  color: widget.appState.accounts.isNotEmpty ? AppColors.success : AppColors.textMuted,
                ),
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
          onTap: () => _onTabSelected(index),
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppColors.surfaceSecondary,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 19,
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isErrorBadge
                          ? AppColors.error
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isErrorBadge
                            ? Colors.white
                            : AppColors.textSecondary,
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

  Widget _buildDesktopTopBar(AppLocalizations l10n) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        border: Border(bottom: BorderSide(color: AppColors.borderOf(context), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getTitleForIndex(_currentIndex, l10n),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textOf(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Interactive Timezone indicator
          InkWell(
            onTap: () => _showTimezoneSelector(context, l10n),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.appState.userTimezone,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Interactive Synced Channels status
          InkWell(
            onTap: () {
              setState(() => _currentIndex = 3);
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.successBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 12, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    l10n.channelsActive(widget.appState.accounts.length),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Interactive Language Switcher Dropdown
          PopupMenuButton<String>(
            tooltip: 'Switch language',
            offset: const Offset(0, 36),
            color: AppColors.surfaceSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppColors.border),
            ),
            onSelected: (code) {
              final locale = AppState.supportedLocales.firstWhere(
                (l) => l.languageCode == code,
              );
              widget.appState.setLocale(locale);
              final displayName = AppState.localeDisplayNames[code] ?? code;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 1),
                  content: Text(l10n.languageSetTo(displayName)),
                ),
              );
            },
            itemBuilder: (_) => AppState.supportedLocales.map((locale) {
              final code = locale.languageCode;
              final name = AppState.localeDisplayNames[code] ?? code;
              final isActive =
                  code == widget.appState.currentLocale.languageCode;
              return PopupMenuItem<String>(
                value: code,
                child: Row(
                  children: [
                    if (isActive)
                      const Icon(Icons.check, size: 14, color: AppColors.accent)
                    else
                      const SizedBox(width: 14),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        color: isActive
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language,
                      size: 13, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    widget.appState.currentLocale.languageCode.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down,
                      size: 14, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Theme Mode Toggle (Dark / Light)
          IconButton(
            icon: Icon(
              widget.appState.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 18,
              color: widget.appState.isDarkMode
                  ? Colors.white70
                  : AppColors.textSecondary,
            ),
            tooltip: widget.appState.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed: widget.appState.toggleTheme,
          ),
          const SizedBox(width: 6),
          // User profile avatar (if available from Google or local login)
          if (widget.appState.localUserPhotoUrl != null &&
              widget.appState.localUserPhotoUrl!.isNotEmpty) ...[
            Tooltip(
              message: '${widget.appState.localUserName ?? "User"} (${widget.appState.localUserEmail ?? ""})',
              child: ClipOval(
                child: Image.network(
                  widget.appState.localUserPhotoUrl!,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      (widget.appState.localUserName?.isNotEmpty == true)
                          ? widget.appState.localUserName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          // User / Logout action button
          IconButton(
            icon: const Icon(Icons.logout, size: 16, color: AppColors.textSecondary),
            tooltip: 'Sign Out (Return to Landing)',
            onPressed: () async {
              await widget.appState.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showTimezoneSelector(BuildContext context, AppLocalizations l10n) {
    final zones = [
      'Local (UTC+5:30)',
      'UTC (Coordinated Universal Time)',
      'US/Eastern (UTC-4:00)',
      'US/Pacific (UTC-7:00)',
      'Europe/London (UTC+1:00)',
      'Europe/Berlin (UTC+2:00)',
      'Asia/Tokyo (UTC+9:00)',
      'Asia/Singapore (UTC+8:00)',
    ];

    AppSheets.showAdaptiveFormSheet(
      context,
      title: Row(
        children: [
          const Icon(Icons.schedule, size: 20, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(l10n.selectTimezoneTitle),
        ],
      ),
      builder: (ctx, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: zones.map((z) {
          final isSelected = widget.appState.userTimezone == z;
          return ListTile(
            dense: true,
            title: Text(
              z,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check, size: 16, color: AppColors.accent)
                : null,
            onTap: () {
              widget.appState.setTimezone(z);
              Navigator.of(ctx).pop();
            },
          );
        }).toList(),
      ),
      actionsBuilder: (ctx) => [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.btnCancel),
        ),
      ],
    );
  }

  String _getTitleForIndex(int index, AppLocalizations l10n) {
    switch (index) {
      case 0:
        return l10n.consoleTitle;
      case 1:
        return l10n.contentLibraryTitle;
      case 2:
        return l10n.calendarTitle;
      case 3:
        return l10n.registryTitle;
      case 4:
        return l10n.settingsTitle;
      default:
        return l10n.appTitle;
    }
  }
}
