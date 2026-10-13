import 'package:flutter/material.dart';
import 'package:no5ocial/core/services/passkey_service.dart';
import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/domain/models/passkey_credential.dart';
import 'package:no5ocial/presentation/state/app_state.dart';

/// Sheet for viewing, registering, testing, and revoking WebAuthn FIDO2 passkeys.
class PasskeyManagementSheet extends StatefulWidget {
  final AppState appState;

  const PasskeyManagementSheet({super.key, required this.appState});

  static Future<void> show(BuildContext context, {required AppState appState}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PasskeyManagementSheet(appState: appState),
    );
  }

  @override
  State<PasskeyManagementSheet> createState() => _PasskeyManagementSheetState();
}

class _PasskeyManagementSheetState extends State<PasskeyManagementSheet> {
  List<PasskeyCredential> _credentials = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadPasskeys();
  }

  Future<void> _loadPasskeys() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    try {
      final list = await PasskeyService.instance.getRegisteredPasskeys();
      if (mounted) {
        setState(() {
          _credentials = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _statusMessage = 'Failed to load registered passkeys: $e';
        });
      }
    }
  }

  Future<void> _promptRegisterPasskey() async {
    final nameController = TextEditingController(
      text: 'Device Passkey (${DateTime.now().day}/${DateTime.now().month})',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: AppColors.accent, size: 20),
            SizedBox(width: 8),
            Text('Register New Passkey'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your platform authenticator (Windows Hello, Touch ID, or Android Biometrics) will create a cryptographic keypair bound to this device.',
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Passkey Friendly Name',
                hintText: 'e.g. Work Phone Fingerprint',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final credentialName = nameController.text.trim().isNotEmpty
          ? nameController.text.trim()
          : 'My Passkey';

      final user = widget.appState;
      final userId = user.localUserId ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      final userEmail = user.localUserEmail ?? 'user@no5ocial.workspace';
      final userName = user.localUserName ?? 'Workspace User';

      await PasskeyService.instance.registerPasskey(
        credentialName: credentialName,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isError = false;
          _statusMessage = 'Passkey "$credentialName" created and registered successfully!';
        });
        await _loadPasskeys();
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        String friendlyError = errStr.replaceAll('Exception:', '').trim();
        if (errStr.contains('RP ID cannot be validated')) {
          friendlyError =
              'Android requires Digital Asset Links verification (assetlinks.json) at https://no5ocial.vercel.app/.well-known/assetlinks.json. Deploy the latest assetlinks.json to Vercel so Android Play Services can validate the domain.';
        }
        setState(() {
          _isProcessing = false;
          _isError = true;
          _statusMessage = 'Registration failed: $friendlyError';
        });
      }
    }
  }

  Future<void> _testPasskeyAuth(PasskeyCredential cred) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final verified = await PasskeyService.instance.authenticatePasskey(credentialId: cred.id);
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isError = !verified;
          _statusMessage = verified
              ? 'Passkey "${cred.name}" verified successfully via device biometric!'
              : 'Passkey verification failed.';
        });
        await _loadPasskeys();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isError = true;
          _statusMessage = 'Verification cancelled or failed: ${e.toString().replaceAll('Exception:', '').trim()}';
        });
      }
    }
  }

  Future<void> _deletePasskey(PasskeyCredential cred) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Passkey'),
        content: Text('Remove passkey "${cred.name}"? You will not be able to use it to sign in on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PasskeyService.instance.deletePasskey(cred.id);
      if (mounted) {
        setState(() {
          _statusMessage = 'Passkey removed.';
          _isError = false;
        });
        await _loadPasskeys();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.vpn_key_rounded, color: AppColors.accent, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Passkeys & Security Keys',
                    style: AppTypography.titleLarge,
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'FIDO2 / WebAuthn passkeys authenticate directly against device biometric hardware (Windows Hello, Touch ID, Android Credential Manager). Zero passwords or tokens are stored.',
            style: AppTypography.bodySecondary,
          ),
          const Divider(height: 24),

          // Feedback Status Banner
          if (_statusMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _isError ? AppColors.errorBg : AppColors.successBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isError ? AppColors.errorBorder : AppColors.successBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isError ? Icons.error_outline : Icons.check_circle_outline,
                    size: 18,
                    color: _isError ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isError ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Waiting for device authenticator...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),

          // Credentials List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _credentials.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.key_off_outlined, size: 36, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            const Text('No Passkeys Registered', style: AppTypography.titleMedium),
                            const SizedBox(height: 4),
                            const Text(
                              'Add a passkey to authenticate securely without passwords.',
                              style: AppTypography.bodySecondary,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _credentials.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final cred = _credentials[idx];
                          final idPreview = cred.id.length > 16
                              ? '${cred.id.substring(0, 8)}...${cred.id.substring(cred.id.length - 8)}'
                              : cred.id;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.fingerprint, color: AppColors.accent, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        cred.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                      tooltip: 'Delete passkey',
                                      onPressed: () => _deletePasskey(cred),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Credential ID: $idPreview',
                                  style: AppTypography.code.copyWith(fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Created: ${DateFormatter.formatRelative(cred.createdAtUtc)}'
                                  '${cred.lastUsedAtUtc != null ? ' • Last used: ${DateFormatter.formatRelative(cred.lastUsedAtUtc!)}' : ''}',
                                  style: AppTypography.bodySecondary.copyWith(fontSize: 11),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: _isProcessing ? null : () => _testPasskeyAuth(cred),
                                  icon: const Icon(Icons.check_circle_outline, size: 14),
                                  label: const Text('Test Verification', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),

          // Register Button
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _isProcessing ? null : _promptRegisterPasskey,
              icon: const Icon(Icons.add_moderator_outlined, size: 18),
              label: const Text('Register New Passkey', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
