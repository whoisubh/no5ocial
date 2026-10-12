import 'package:flutter/material.dart';
import 'legal_page_layout.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageLayout(
      currentTab: LegalTab.privacy,
      title: 'Privacy Policy',
      lastUpdated: 'October 2026',
      summary:
          'Your privacy is our utmost priority. no5ocial is designed with zero-knowledge architecture. Read below to understand how your credentials and content drafts are secured locally.',
      children: [
        LegalSectionCard(
          number: '1',
          title: 'Local Data Storage & Control',
          body:
              'Your privacy is our utmost priority. no5ocial is designed with zero-knowledge architecture: all your campaign data, drafts, connected profiles, and publishing queues are stored purely on your local device. We do not transmit or mirror your post content to remote telemetry or central storage.',
        ),
        LegalSectionCard(
          number: '2',
          title: 'Authentication & Credentials',
          body:
              'When you sign in locally or connect social media profiles, tokens and identifiers are handled locally. no5ocial does not harvest credentials, monitor private direct messages, or collect private user profiles.',
        ),
        LegalSectionCard(
          number: '3',
          title: 'Analytics and Telemetry',
          body:
              'no5ocial does not embed intrusive third-party trackers, behavioral profiling scripts, or ad networks. We believe in building clean software that respects your workflow and boundaries.',
        ),
        LegalSectionCard(
          number: '4',
          title: 'Clearing and Resetting Your Data',
          body:
              'You retain complete ownership over your data at all times. You can wipe all local databases, connected channels, and queued jobs with a single click in Workspace Settings -> Database Management.',
        ),
        LegalSectionCard(
          number: '5',
          title: 'Inquiries & Contact',
          body:
              'If you have questions regarding this Privacy Policy or security practices, contact privacy@shaadow.local.',
        ),
      ],
    );
  }
}
