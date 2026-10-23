import 'package:flutter/material.dart';
import 'legal_page_layout.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageLayout(
      currentTab: LegalTab.disclaimer,
      title: 'Legal & Operational Disclaimer',
      lastUpdated: 'October 2026',
      summary:
          'Important disclaimers regarding third-party social network API integrations, platform rate limits, local-first data caching, and independent operation.',
      children: [
        LegalSectionCard(
          number: '1',
          title: 'No Affiliation with Third-Party Platforms',
          body:
              'no5ocial is an independent productivity workspace developed by Shaadow. It is not endorsed, certified, or directly affiliated with Meta Platforms (Instagram, Facebook), X Corp., LinkedIn Corporation, or Google LLC / YouTube. All brand trademarks belong to their respective owners.',
        ),
        LegalSectionCard(
          number: '2',
          title: 'API Availability and Rate Limits',
          body:
              'Third-party social network APIs are subject to change, downtime, rate limiting, and deprecations at the discretion of the platforms. While no5ocial provides robust preflight validation, duplicate guards, and retry mechanics, uninterrupted service across external networks cannot be guaranteed.',
        ),
        LegalSectionCard(
          number: '3',
          title: 'Local State & Backups',
          body:
              'Because no5ocial utilizes local-first client storage, clearing your application data will remove your locally saved drafts and schedules. Ensure essential campaign copies are maintained in your external content records.',
        ),
        LegalSectionCard(
          number: '4',
          title: 'Preview & Demonstration Environments',
          body:
              'Certain features and channel previews may operate in test mode until live credentials are connected. Test actions will not alter live platform feeds unless connected via official OAuth workflows.',
        ),
      ],
    );
  }
}
