import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum LegalTab {
  terms,
  privacy,
  disclaimer,
}

class LegalPageLayout extends StatelessWidget {
  final LegalTab currentTab;
  final String title;
  final String lastUpdated;
  final String summary;
  final List<Widget> children;

  const LegalPageLayout({
    super.key,
    required this.currentTab,
    required this.title,
    required this.lastUpdated,
    required this.summary,
    required this.children,
  });

  void _navigateToTab(BuildContext context, LegalTab tab) {
    if (tab == currentTab) return;
    String route = '/legal/terms';
    switch (tab) {
      case LegalTab.terms:
        route = '/legal/terms';
        break;
      case LegalTab.privacy:
        route = '/legal/privacy';
        break;
      case LegalTab.disclaimer:
        route = '/legal/disclaimer';
        break;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final headingColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Row(
                    children: [
                      // Back Button
                      InkWell(
                        onTap: () => _handleBack(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_rounded, size: 16, color: headingColor),
                              const SizedBox(width: 6),
                              Text(
                                'Back',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: headingColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Official Brand Logo
                      InkWell(
                        onTap: () => _handleBack(context),
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          isDark ? 'assets/logo/no5ocial_white.png' : 'assets/logo/no5ocial.png',
                          height: 26,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Image.asset(
                            'assets/logo/no5ocial_N.png',
                            height: 26,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Legal Navigation Tabs (Responsive)
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNavTab(
                                context: context,
                                label: 'Terms',
                                tab: LegalTab.terms,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 6),
                              _buildNavTab(
                                context: context,
                                label: 'Privacy',
                                tab: LegalTab.privacy,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 6),
                              _buildNavTab(
                                context: context,
                                label: 'Disclaimer',
                                tab: LegalTab.disclaimer,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Document Header Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3865F6).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF3865F6)),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Last updated: $lastUpdated',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF3865F6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: headingColor,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                summary,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Section List
                        ...children,

                        const SizedBox(height: 32),

                        // Cross-Navigation Footer
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              Text(
                                '© 2026 no5ocial • Shaadow Workflow. All rights reserved.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: subtextColor,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildFooterLink(context, 'Terms', LegalTab.terms),
                                  _buildSeparator(subtextColor),
                                  _buildFooterLink(context, 'Privacy', LegalTab.privacy),
                                  _buildSeparator(subtextColor),
                                  _buildFooterLink(context, 'Disclaimer', LegalTab.disclaimer),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab({
    required BuildContext context,
    required String label,
    required LegalTab tab,
    required bool isDark,
  }) {
    final isActive = tab == currentTab;
    return InkWell(
      onTap: () => _navigateToTab(context, tab),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF3865F6)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context, String label, LegalTab tab) {
    final isActive = tab == currentTab;
    return InkWell(
      onTap: () => _navigateToTab(context, tab),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? const Color(0xFF3865F6) : const Color(0xFF64748B),
          decoration: isActive ? TextDecoration.underline : TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildSeparator(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text('•', style: TextStyle(color: color, fontSize: 10)),
    );
  }
}

class LegalSectionCard extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const LegalSectionCard({
    super.key,
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final headingColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF0F172A);
    final bodyColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF3865F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3865F6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: headingColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.68,
              color: bodyColor,
            ),
          ),
        ],
      ),
    );
  }
}
