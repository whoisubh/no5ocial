import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: const [
              Text(
                'Terms of Service',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Last updated: October 2026',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              SizedBox(height: 24),
              _LegalSection(
                title: '1. Acceptance of Terms',
                body:
                    'By accessing or using no5ocial ("the Application"), you agree to be bound by these Terms of Service. If you do not agree to these terms, do not access or use the application.',
              ),
              _LegalSection(
                title: '2. Local-First Operation & Privacy',
                body:
                    'no5ocial operates as a local-first workspace. All your content drafts, schedules, connected platform profiles, and publishing logs are stored strictly on your local device. no5ocial does not operate remote database servers to store your private post content or personal identification.',
              ),
              _LegalSection(
                title: '3. Third-Party Platform Policies',
                body:
                    'When connecting accounts and publishing content to third-party social networks (such as Instagram, X, LinkedIn, YouTube, and others), you must comply with their respective Developer Policies, Terms of Service, and Community Guidelines. no5ocial is not responsible for penalties, suspensions, or rate limits enforced by third-party platforms.',
              ),
              _LegalSection(
                title: '4. User Conduct and Responsibilities',
                body:
                    'You are solely responsible for all content composed, scheduled, or published through no5ocial. You agree not to distribute illegal content, hate speech, automated spam, or intellectual property infringements.',
              ),
              _LegalSection(
                title: '5. Limitation of Liability',
                body:
                    'no5ocial is provided "as is" and "as available" without warranties of any kind. Under no circumstances shall no5ocial or its developers be liable for direct, indirect, incidental, or consequential damages resulting from lost content, network timeouts, or delayed publications.',
              ),
              _LegalSection(
                title: '6. Updates and Modifications',
                body:
                    'We reserve the right to modify these Terms of Service at any time. Updates will be reflected in the application with a revised timestamp.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String body;

  const _LegalSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
