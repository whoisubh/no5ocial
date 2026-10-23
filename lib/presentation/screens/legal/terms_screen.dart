import 'package:flutter/material.dart';
import 'legal_page_layout.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageLayout(
      currentTab: LegalTab.terms,
      title: 'Terms of Service',
      lastUpdated: 'October 2026',
      summary:
          'Please read these Terms of Service carefully before utilizing no5ocial. By accessing or publishing content via the workspace, you agree to comply with all guidelines detailed below.',
      children: [
        LegalSectionCard(
          number: '1',
          title: 'Acceptance of Terms',
          body:
              'By accessing or using no5ocial ("the Application"), you agree to be bound by these Terms of Service. If you do not agree to these terms, do not access or use the application.',
        ),
        LegalSectionCard(
          number: '2',
          title: 'Local-First Operation & Privacy',
          body:
              'no5ocial operates as a privacy-focused local workspace. All your content drafts, schedules, connected platform profiles, and publishing logs are stored strictly on your local device. no5ocial does not operate remote servers to store your private post content or personal identification.',
        ),
        LegalSectionCard(
          number: '3',
          title: 'Third-Party Platform Policies',
          body:
              'When connecting accounts and publishing content to third-party social networks (such as Instagram, X, LinkedIn, YouTube, and others), you must comply with their respective Developer Policies, Terms of Service, and Community Guidelines. no5ocial is not responsible for penalties, suspensions, or rate limits enforced by third-party platforms.',
        ),
        LegalSectionCard(
          number: '4',
          title: 'User Conduct and Responsibilities',
          body:
              'You are solely responsible for all content composed, scheduled, or published through no5ocial. You agree not to distribute illegal content, hate speech, automated spam, or intellectual property infringements.',
        ),
        LegalSectionCard(
          number: '5',
          title: 'Limitation of Liability',
          body:
              'no5ocial is provided "as is" and "as available" without warranties of any kind. Under no circumstances shall no5ocial or its developers be liable for direct, indirect, incidental, or consequential damages resulting from lost content, network timeouts, or delayed publications.',
        ),
        LegalSectionCard(
          number: '6',
          title: 'Updates and Modifications',
          body:
              'We reserve the right to modify these Terms of Service at any time. Updates will be reflected in the application with a revised timestamp.',
        ),
      ],
    );
  }
}
