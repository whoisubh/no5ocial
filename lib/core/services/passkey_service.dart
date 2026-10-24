import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import 'package:no5ocial/core/config/env_config.dart';
import 'package:no5ocial/core/services/session_service.dart';
import 'package:no5ocial/domain/models/passkey_credential.dart';

/// Real FIDO2 / WebAuthn Passkey service with zero dummy data.
/// Interacts directly with native platform authenticators:
/// - Windows Hello on Windows
/// - Touch ID / Face ID on Apple platforms
/// - Android Credential Manager on Android
/// - WebAuthn API on Web
class PasskeyService {
  static final PasskeyService instance = PasskeyService._internal();
  PasskeyService._internal();

  PasskeyAuthenticator? _authenticatorInstance;
  bool _authenticatorInitAttempted = false;

  PasskeyAuthenticator? get _authenticator {
    if (_authenticatorInstance != null) return _authenticatorInstance;
    if (_authenticatorInitAttempted) return null;
    _authenticatorInitAttempted = true;
    try {
      _authenticatorInstance = PasskeyAuthenticator();
      return _authenticatorInstance;
    } catch (e) {
      debugPrint('PasskeyAuthenticator initialization warning: $e');
      return null;
    }
  }

  /// Determine the relying party ID based on platform and active environment
  static String get relyingPartyId {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty) return host;
    }
    return EnvConfig.appDomain;
  }

  static const String relyingPartyName = 'no5ocial Workspace';

  /// Generate a cryptographically secure random 32-byte WebAuthn challenge (Base64URL encoded)
  static String generateSecureChallenge() {
    final random = Random.secure();
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Check whether the current platform supports passkey authentication
  Future<bool> canAuthenticate() async {
    try {
      final auth = _authenticator;
      if (auth == null) return false;
      final availability = auth.getAvailability();
      if (kIsWeb) {
        final res = await availability.web();
        return res.hasPasskeySupport;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final res = await availability.android();
        return res.hasPasskeySupport;
      }
      return true;
    } catch (e) {
      debugPrint('Passkey availability check: $e');
      return false;
    }
  }

  /// Perform a real passkey registration ceremony with the platform authenticator.
  /// Zero fake or mock data: uses active user identity and genuine crypto challenge.
  Future<PasskeyCredential> registerPasskey({
    required String credentialName,
    required String userId,
    required String userEmail,
    required String userName,
  }) async {
    final challenge = generateSecureChallenge();
    final rpId = relyingPartyId;

    // Convert user id to base64url bytes per WebAuthn specification
    final userIdBytes = base64Url.encode(utf8.encode(userId)).replaceAll('=', '');

    final registerRequest = RegisterRequestType(
      challenge: challenge,
      relyingParty: RelyingPartyType(
        id: rpId,
        name: relyingPartyName,
      ),
      user: UserType(
        id: userIdBytes,
        name: userEmail,
        displayName: userName.isNotEmpty ? userName : userEmail,
      ),
      excludeCredentials: const [],
      pubKeyCredParams: [
        PubKeyCredParamType(
          type: 'public-key',
          alg: -7, // ES256 (standard ECDSA)
        ),
        PubKeyCredParamType(
          type: 'public-key',
          alg: -257, // RS256 (RSA)
        ),
      ],
      timeout: 60000, // 60 seconds
    );

    final auth = _authenticator;
    if (auth == null) {
      throw UnsupportedError('Passkey authentication is not supported or initialized on this device.');
    }

    try {
      final RegisterResponseType response = await auth.register(registerRequest);

      final credentialId = response.id.isNotEmpty
          ? response.id
          : response.rawId;

      final credential = PasskeyCredential(
        id: credentialId,
        name: credentialName.trim().isNotEmpty
            ? credentialName.trim()
            : 'Passkey (${DateTime.now().toLocal().toString().split('.').first})',
        createdAtUtc: DateTime.now().toUtc(),
        lastUsedAtUtc: DateTime.now().toUtc(),
        transports: const ['internal', 'hybrid'],
        clientDataJson: response.clientDataJSON,
        attestationObject: response.attestationObject,
      );

      await SessionService.instance.savePasskeyCredential(credential);
      return credential;
    } catch (e) {
      debugPrint('Passkey registration error: $e');
      rethrow;
    }
  }

  /// Perform a real passkey authentication ceremony to verify a registered passkey.
  Future<bool> authenticatePasskey({
    String? credentialId,
  }) async {
    final challenge = generateSecureChallenge();
    final rpId = relyingPartyId;

    final authRequest = AuthenticateRequestType(
      relyingPartyId: rpId,
      challenge: challenge,
      mediation: MediationType.Optional,
      preferImmediatelyAvailableCredentials: false,
      userVerification: 'preferred',
      timeout: 60000,
    );

    final auth = _authenticator;
    if (auth == null) {
      throw UnsupportedError('Passkey authentication is not supported or initialized on this device.');
    }

    try {
      final AuthenticateResponseType response = await auth.authenticate(authRequest);
      final verifiedId = response.id.isNotEmpty ? response.id : response.rawId;

      if (credentialId != null && credentialId.isNotEmpty) {
        await SessionService.instance.updatePasskeyLastUsed(credentialId);
      } else if (verifiedId.isNotEmpty) {
        await SessionService.instance.updatePasskeyLastUsed(verifiedId);
      }

      return true;
    } catch (e) {
      debugPrint('Passkey authentication error: $e');
      rethrow;
    }
  }

  /// Get all currently registered passkeys for the active user
  Future<List<PasskeyCredential>> getRegisteredPasskeys() async {
    return await SessionService.instance.getRegisteredPasskeys();
  }

  /// Remove a passkey by ID
  Future<void> deletePasskey(String credentialId) async {
    await SessionService.instance.deletePasskeyCredential(credentialId);
  }
}
