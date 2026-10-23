import 'package:flutter/material.dart';
import 'legal_page_layout.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalPageLayout(
      currentTab: LegalTab.privacy,
      title: 'Privacy Policy & Google API User Data Disclosure',
      lastUpdated: 'October 2026',
      summary:
          'This Privacy Policy details how no5ocial accesses, collects, utilizes, stores, and protects user information—including Google and YouTube API user data—under our local-first architecture and in full compliance with the Google API Services User Data Policy.',
      children: [
        LegalSectionCard(
          number: '1',
          title: 'Overview & Application Purpose',
          body:
              'no5ocial ("the Application", "we", "our") is a privacy-first multi-channel social media publishing and scheduling workspace. The application enables content creators, marketing teams, and businesses to compose, plan, preflight, schedule, and publish video and post content across multiple authorized platforms, including YouTube, Instagram, X (Twitter), and LinkedIn.\n\nno5ocial operates on a zero-knowledge, local-first architecture. We do not operate centralized cloud servers that harvest, track, or mirror your personal drafts, credentials, or social media content.',
        ),
        LegalSectionCard(
          number: '2',
          title: 'Google User Data We Access & Collect',
          body:
              'When you authenticate using Google Sign-In or connect your YouTube channel, no5ocial requests only the least-privileged OAuth 2.0 scopes necessary to provide core publishing services:\n\n'
              '• Basic Profile Information (email, profile): Google User ID, Display Name, Email Address, and Profile Avatar URL. This data is used solely to establish and display your authenticated workspace session.\n\n'
              '• YouTube Data API (youtube.upload, youtube.readonly, youtube.force-ssl): When you explicitly connect YouTube as a destination channel, no5ocial accesses channel metadata (Channel Name, ID, Thumbnail) and requests upload permissions strictly to publish videos, descriptions, tags, and thumbnails on your behalf.\n\n'
              '• What We Never Access: no5ocial never requests, reads, or stores your private Google Drive documents, Gmail messages, contacts, payment methods, browsing history, or search logs.',
        ),
        LegalSectionCard(
          number: '3',
          title: 'How We Use Google User Data',
          body:
              'no5ocial uses information received from Google APIs strictly for the following operational purposes:\n\n'
              '1. Workspace Authentication: To verify your identity and protect access to your local workspace.\n'
              '2. Channel Integration & Publishing: To query your authorized YouTube channel identifiers, upload video assets, set publication schedules, apply titles/tags, and monitor delivery status per your explicit instruction.\n'
              '3. Quota & Preflight Validation: To inspect channel status and quota availability to prevent failed publication attempts.\n\n'
              'We never use your Google user data for background surveillance, undisclosed telemetry, or automated profiling.',
        ),
        LegalSectionCard(
          number: '4',
          title: 'Google API Services User Data Policy Compliance (Limited Use)',
          body:
              "no5ocial's use and transfer of information received from Google APIs to any other app will adhere to the Google API Services User Data Policy, including the Limited Use requirements.\n\n"
              'Specifically:\n'
              '• We only use Google data to provide and improve user-facing features that are prominent in the no5ocial user interface.\n'
              '• We do not transfer Google user data to external parties unless necessary to provide or improve these user-facing features, comply with applicable law, or as part of a merger/acquisition with user consent.\n'
              '• We do not use or transfer Google user data to serve advertisements, including personalized, re-targeted, or interest-based advertising.\n'
              '• We do not allow humans to read Google user data unless you have given explicit affirmative consent, it is necessary for security purposes (such as investigating a bug or abuse), or it is required to comply with applicable law.',
        ),
        LegalSectionCard(
          number: '5',
          title: 'Strict Prohibition on Data Sale & Third-Party Sharing',
          body:
              'no5ocial has a strict, uncompromising NO-SALE policy:\n\n'
              '• We NEVER sell, rent, lease, trade, or monetize your Google user data, YouTube content, or personal identifiers to third parties.\n'
              '• We NEVER share your Google user data with data brokers, ad networks, behavioral tracking firms, or data analytics aggregators.\n'
              '• All communication with Google APIs occurs over secure, encrypted TLS/HTTPS connections directly between your client device and Google servers.',
        ),
        LegalSectionCard(
          number: '6',
          title: 'No Artificial Intelligence (AI) Model Training',
          body:
              'Your Google user data, video uploads, metadata, post drafts, and captions are NEVER used to train, evaluate, fine-tune, or develop artificial intelligence (AI), machine learning (ML), or large language models (LLMs). Your creative work remains your intellectual property and is never harvested as training data.',
        ),
        LegalSectionCard(
          number: '7',
          title: 'Prohibition of AI NCII (Non-Consensual Intimate Imagery)',
          body:
              'In strict accordance with the Google APIs Terms of Service and Developer Policies:\n\n'
              'no5ocial does NOT generate, process, alter, distribute, or facilitate Non-Consensual Intimate Imagery (NCII), synthetic non-consensual sexual content, deepfakes, or sexually explicit material using Google APIs or across any connected platform. Accounts attempting to use no5ocial for unlawful, non-consensual, or sexually abusive material will be immediately rejected and reported.',
        ),
        LegalSectionCard(
          number: '8',
          title: 'Data Storage, Retention, and Security',
          body:
              '• 100% Local Storage: Authenticated tokens, publishing queues, brand settings, and post drafts are saved strictly on your local device vault. We operate zero remote backend database servers that cache your content or credentials.\n\n'
              '• Token Protection: Access and refresh tokens are isolated and handled through secure platform storage.\n\n'
              '• Retention: Data persists only for the duration you choose to retain it in your workspace. We do not maintain off-site backups or remote archives of your personal data.',
        ),
        LegalSectionCard(
          number: '9',
          title: 'User Control, Access Revocation, and Data Deletion',
          body:
              'You retain complete sovereignty over your data and channel permissions at all times:\n\n'
              '1. Disconnecting within no5ocial: Navigate to Workspace Settings -> Connected Channels and click "Disconnect" on any channel to immediately purge associated tokens and metadata from your device.\n\n'
              '2. Revoking Access via Google: You can revoke no5ocial\'s access to your Google Account at any time by visiting Google Account Security Settings: https://myaccount.google.com/permissions\n\n'
              '3. Full Data Purge: You can delete all locally saved drafts, accounts, and settings with one click via Workspace Settings -> Data & Storage -> Reset Workspace Data, or by clearing your application data.',
        ),
        LegalSectionCard(
          number: '10',
          title: 'Third-Party Social Network Terms',
          body:
              'By utilizing YouTube integrations via no5ocial, users are also bound by the YouTube Terms of Service (https://www.youtube.com/t/terms) and the Google Privacy Policy (https://policies.google.com/privacy). When connecting Instagram, X, or LinkedIn, users must comply with their respective Developer Terms and Privacy Policies.',
        ),
        LegalSectionCard(
          number: '11',
          title: 'Contact Information & Inquiries',
          body:
              'If you have questions, feedback, or concerns regarding this Privacy Policy, our Google API data handling practices, or your data sovereignty, please contact our team:\n\n'
              '• Legal & Privacy Contact: privacy@no5ocial.vercel.app\n'
              '• Security & Development: support@shaadow.io\n'
              '• Website: https://no5ocial.vercel.app',
        ),
      ],
    );
  }
}
