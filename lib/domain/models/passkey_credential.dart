import 'dart:convert';

/// Represents a registered FIDO2 / WebAuthn passkey credential
class PasskeyCredential {
  final String id;
  final String name;
  final DateTime createdAtUtc;
  final DateTime? lastUsedAtUtc;
  final List<String> transports;
  final String? clientDataJson;
  final String? attestationObject;

  const PasskeyCredential({
    required this.id,
    required this.name,
    required this.createdAtUtc,
    this.lastUsedAtUtc,
    this.transports = const [],
    this.clientDataJson,
    this.attestationObject,
  });

  PasskeyCredential copyWith({
    String? id,
    String? name,
    DateTime? createdAtUtc,
    DateTime? lastUsedAtUtc,
    List<String>? transports,
    String? clientDataJson,
    String? attestationObject,
  }) {
    return PasskeyCredential(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      lastUsedAtUtc: lastUsedAtUtc ?? this.lastUsedAtUtc,
      transports: transports ?? this.transports,
      clientDataJson: clientDataJson ?? this.clientDataJson,
      attestationObject: attestationObject ?? this.attestationObject,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at_utc': createdAtUtc.toIso8601String(),
      'last_used_at_utc': lastUsedAtUtc?.toIso8601String(),
      'transports': transports,
      'client_data_json': clientDataJson,
      'attestation_object': attestationObject,
    };
  }

  factory PasskeyCredential.fromJson(Map<String, dynamic> json) {
    return PasskeyCredential(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Passkey Credential',
      createdAtUtc: DateTime.tryParse(json['created_at_utc'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      lastUsedAtUtc: json['last_used_at_utc'] != null
          ? DateTime.tryParse(json['last_used_at_utc'] as String)?.toUtc()
          : null,
      transports: (json['transports'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      clientDataJson: json['client_data_json'] as String?,
      attestationObject: json['attestation_object'] as String?,
    );
  }

  static List<PasskeyCredential> listFromJson(String jsonStr) {
    if (jsonStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded
            .map((e) => PasskeyCredential.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static String listToJson(List<PasskeyCredential> list) {
    return jsonEncode(list.map((e) => e.toJson()).toList());
  }
}
