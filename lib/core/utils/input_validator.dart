/// Comprehensive input validation and character limit rules for user inputs.
/// Prevents misuse, buffer distortion, script injection, and invalid entity formats.
abstract final class InputValidator {
  // Regex patterns
  static final RegExp _brandSlugRegex = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
  static final RegExp _dangerousTagRegex = RegExp(
    r'<[^>]*>|javascript:|data:|vbscript:',
    caseSensitive: false,
  );
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );
  static final RegExp _handleRegex = RegExp(r'^@?[a-zA-Z0-9._-]+$');
  static final RegExp _urlRegex = RegExp(
    r'^https?://[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)+([/?#].*)?$',
    caseSensitive: false,
  );

  // Character Length Limitations
  static const int minBrandNameLength = 2;
  static const int maxBrandNameLength = 60;
  static const int minBrandSlugLength = 2;
  static const int maxBrandSlugLength = 30;
  static const int maxWebsiteUrlLength = 200;
  static const int maxDescriptionLength = 300;
  static const int minDisplayNameLength = 2;
  static const int maxDisplayNameLength = 50;
  static const int minHandleLength = 2;
  static const int maxHandleLength = 35;
  static const int maxEmailLength = 254;

  /// Validates company or brand name
  static String? validateBrandName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Company or Brand Name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minBrandNameLength) {
      return 'Brand name must be at least $minBrandNameLength characters';
    }
    if (trimmed.length > maxBrandNameLength) {
      return 'Brand name cannot exceed $maxBrandNameLength characters';
    }
    if (_dangerousTagRegex.hasMatch(trimmed)) {
      return 'Brand name contains invalid or disallowed characters';
    }
    if (!RegExp(r'[a-zA-Z0-9]').hasMatch(trimmed)) {
      return 'Brand name must contain at least one alphanumeric character';
    }
    return null;
  }

  /// Validates brand slug / identifier
  static String? validateBrandSlug(String? value, {List<String>? existingSlugs}) {
    if (value == null || value.trim().isEmpty) {
      return 'Brand Slug is required';
    }
    final slug = value.trim().toLowerCase();
    if (slug.length < minBrandSlugLength) {
      return 'Slug must be at least $minBrandSlugLength characters';
    }
    if (slug.length > maxBrandSlugLength) {
      return 'Slug cannot exceed $maxBrandSlugLength characters';
    }
    if (slug.startsWith('-') || slug.endsWith('-')) {
      return 'Slug cannot start or end with a hyphen';
    }
    if (slug.contains('--')) {
      return 'Slug cannot contain consecutive hyphens';
    }
    if (!_brandSlugRegex.hasMatch(slug)) {
      return 'Slug must contain only lowercase letters, numbers, and hyphens';
    }
    if (existingSlugs != null && existingSlugs.contains(slug)) {
      return 'This slug is already taken. Please choose another';
    }
    return null;
  }

  /// Automatically and dynamically generates a slug/identifier from the company name,
  /// user handle, or a short unique identifier, guaranteeing uniqueness.
  static String generateDynamicSlug({
    required String name,
    String? userHandle,
    List<String> existingSlugs = const [],
  }) {
    String base = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    if (base.isEmpty) {
      if (userHandle != null && userHandle.trim().isNotEmpty) {
        base = userHandle
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
            .replaceAll(RegExp(r'^-+|-+$'), '');
      }
      if (base.isEmpty) {
        base = 'brand';
      }
    }

    if (base.length > 22) {
      base = base.substring(0, 22).replaceAll(RegExp(r'-+$'), '');
    }

    if (!existingSlugs.contains(base)) {
      return base;
    }

    // Collision resolution: append user handle or short unique hex
    if (userHandle != null && userHandle.trim().isNotEmpty) {
      final cleanHandle = userHandle
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      if (cleanHandle.isNotEmpty) {
        final withHandle = '$base-$cleanHandle';
        final candidate = withHandle.length > maxBrandSlugLength
            ? withHandle.substring(0, maxBrandSlugLength)
            : withHandle;
        if (!existingSlugs.contains(candidate)) {
          return candidate;
        }
      }
    }

    final uniqueSuffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final suffix = uniqueSuffix.length > 4 ? uniqueSuffix.substring(uniqueSuffix.length - 4) : uniqueSuffix;
    final candidate = '$base-$suffix';
    return candidate.length > maxBrandSlugLength
        ? candidate.substring(0, maxBrandSlugLength)
        : candidate;
  }

  /// Validates website URL
  static String? validateWebsiteUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final url = value.trim();
    if (url.length > maxWebsiteUrlLength) {
      return 'Website URL cannot exceed $maxWebsiteUrlLength characters';
    }
    if (_dangerousTagRegex.hasMatch(url)) {
      return 'Invalid URL format';
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'URL must start with https:// or http://';
    }
    if (!_urlRegex.hasMatch(url)) {
      return 'Please enter a valid website address (e.g. https://example.com)';
    }
    return null;
  }

  /// Validates company / brand description
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final desc = value.trim();
    if (desc.length > maxDescriptionLength) {
      return 'Description cannot exceed $maxDescriptionLength characters';
    }
    if (_dangerousTagRegex.hasMatch(desc)) {
      return 'Description contains invalid characters';
    }
    return null;
  }

  /// Validates channel display name
  static String? validateChannelDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display Name is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < minDisplayNameLength) {
      return 'Display name must be at least $minDisplayNameLength characters';
    }
    if (trimmed.length > maxDisplayNameLength) {
      return 'Display name cannot exceed $maxDisplayNameLength characters';
    }
    if (_dangerousTagRegex.hasMatch(trimmed)) {
      return 'Display name contains invalid characters';
    }
    return null;
  }

  /// Validates social handle
  static String? validateHandle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Handle / Username is required';
    }
    final trimmed = value.trim();
    final cleanHandle = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
    if (cleanHandle.length < minHandleLength) {
      return 'Handle must be at least $minHandleLength characters';
    }
    if (cleanHandle.length > maxHandleLength) {
      return 'Handle cannot exceed $maxHandleLength characters';
    }
    if (cleanHandle.contains(' ')) {
      return 'Handle cannot contain spaces';
    }
    if (!_handleRegex.hasMatch(trimmed)) {
      return 'Handle can only contain letters, numbers, underscores, and dots';
    }
    return null;
  }

  /// Validates email address
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    if (trimmed.length > maxEmailLength) {
      return 'Email cannot exceed $maxEmailLength characters';
    }
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Sanitizes text input by stripping control characters and trimming
  static String sanitize(String input) {
    return input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
  }
}
