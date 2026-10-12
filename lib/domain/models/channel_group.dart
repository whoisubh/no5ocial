import 'dart:convert';

/// Represents a group of social media profiles (channels) across platforms
/// belonging to a brand or product line.
///
/// Example: A company's flagship product might have an Instagram, X, LinkedIn,
/// and YouTube channel. Grouping them allows one-click multi-destination selection
/// in the composer.
class ChannelGroup {
  final String id;
  final String brandId;
  final String name;
  final String? description;
  final List<String> accountIds;
  final DateTime createdAtUtc;

  const ChannelGroup({
    required this.id,
    required this.brandId,
    required this.name,
    this.description,
    required this.accountIds,
    required this.createdAtUtc,
  });

  ChannelGroup copyWith({
    String? id,
    String? brandId,
    String? name,
    String? description,
    List<String>? accountIds,
    DateTime? createdAtUtc,
  }) {
    return ChannelGroup(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      name: name ?? this.name,
      description: description ?? this.description,
      accountIds: accountIds ?? this.accountIds,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand_id': brandId,
      'name': name,
      'description': description,
      'account_ids': jsonEncode(accountIds),
      'created_at_utc': createdAtUtc.toIso8601String(),
    };
  }

  factory ChannelGroup.fromMap(Map<String, dynamic> map) {
    List<String> accounts = [];
    if (map['account_ids'] != null) {
      try {
        final decoded = jsonDecode(map['account_ids'] as String);
        if (decoded is List) {
          accounts = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return ChannelGroup(
      id: map['id'] as String,
      brandId: map['brand_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Untitled Group',
      description: map['description'] as String?,
      accountIds: accounts,
      createdAtUtc: DateTime.tryParse(map['created_at_utc'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
