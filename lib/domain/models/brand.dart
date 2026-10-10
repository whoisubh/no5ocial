/// A Brand represents a distinct content identity in the Shaadow portfolio.
/// Examples: Shaadow, Shaadow Works, Boofer, Favtunes, Galaxious, Owl and Fowl Studios.
class Brand {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? websiteUrl;
  final bool isActive;
  final DateTime createdAtUtc;

  const Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.websiteUrl,
    this.isActive = true,
    required this.createdAtUtc,
  });

  Brand copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? websiteUrl,
    bool? isActive,
    DateTime? createdAtUtc,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      isActive: isActive ?? this.isActive,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'website_url': websiteUrl,
        'is_active': isActive,
        'created_at_utc': createdAtUtc.toIso8601String(),
      };

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        description: json['description'] as String?,
        websiteUrl: json['website_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAtUtc: DateTime.parse(json['created_at_utc'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Brand && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
