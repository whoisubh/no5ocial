import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                'Privacy Policy',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Last updated: October 2026',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              SizedBox(height: 24),
              _PolicySection(
                title: '1. Local Data Storage & Control',
                body:
                    'Your privacy is our utmost priority. no5ocial is designed with zero-knowledge architecture: all your campaign data, drafts, connected profiles, and publishing queues are stored purely on your local device. We do not transmit or mirror your post content to remote telemetry or central storage.',
              ),
              _PolicySection(
                title: '2. Authentication & Credentials',
                body:
                    'When you sign in locally or connect social media profiles, tokens and identifiers are handled locally. no5ocial does not harvest credentials, monitor private direct messages, or collect private user profiles.',
              ),
              _PolicySection(
                title: '3. Analytics and Telemetry',
                body:
                    'no5ocial does not embed intrusive third-party trackers, behavioral profiling scripts, or ad networks. We believe in building clean software that respects your workflow and boundaries.',
              ),
              _PolicySection(
                title: '4. Clearing and Resetting Your Data',
                body:
                    'You retain complete ownership over your data at all times. You can wipe all local databases, connected channels, and queued jobs with a single click in Workspace Settings -> Database Management.',
              ),
              _PolicySection(
                title: '5. Inquiries & Contact',
                body:
                    'If you have questions regarding this Privacy Policy or security practices, contact privacy@shaadow.local.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

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
