import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disclaimer'),
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
                'Legal & Operational Disclaimer',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Last updated: October 2026',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              SizedBox(height: 24),
              _DisclaimerSection(
                title: 'No Affiliation with Third-Party Platforms',
                body:
                    'no5ocial is an independent productivity workspace developed by Shaadow. It is not endorsed, certified, or directly affiliated with Meta Platforms (Instagram, Facebook), X Corp., LinkedIn Corporation, or Google LLC / YouTube. All brand trademarks belong to their respective owners.',
              ),
              _DisclaimerSection(
                title: 'API Availability and Rate Limits',
                body:
                    'Third-party social network APIs are subject to change, downtime, rate limiting, and deprecations at the discretion of the platforms. While no5ocial provides robust preflight validation, idempotency guards, and retry mechanics, uninterrupted service across external networks cannot be guaranteed.',
              ),
              _DisclaimerSection(
                title: 'Local State & Backups',
                body:
                    'Because no5ocial utilizes local-first client storage, clearing your browser cache or application data without exporting will remove your local draft database. Ensure essential campaign copies are maintained in your external content records.',
              ),
              _DisclaimerSection(
                title: 'Simulated and Demonstration Environments',
                body:
                    'Certain integration modules and mock adapters may run in simulated mode for testing and security verification. Simulated posts will not alter live platform feeds unless connected via official production OAuth workflows.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisclaimerSection extends StatelessWidget {
  final String title;
  final String body;

  const _DisclaimerSection({required this.title, required this.body});

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
