import '../enums/media_type.dart';

/// Represents a media asset reference (image, video, carousel item).
class MediaAsset {
  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? checksum;
  final String? localPreviewUrl;
  final MediaType mediaType;
  final DateTime createdAtUtc;

  const MediaAsset({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.width,
    this.height,
    this.durationMs,
    this.checksum,
    this.localPreviewUrl,
    required this.mediaType,
    required this.createdAtUtc,
  });

  /// Formatted size in human readable KB or MB.
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Aspect ratio string (e.g. "16:9", "1:1", "9:16") if dimensions are known.
  String? get aspectRatioString {
    if (width == null || height == null || height == 0) return null;
    final ratio = width! / height!;
    if ((ratio - 1.0).abs() < 0.05) return '1:1';
    if ((ratio - (16 / 9)).abs() < 0.05) return '16:9';
    if ((ratio - (9 / 16)).abs() < 0.05) return '9:16';
    if ((ratio - (4 / 5)).abs() < 0.05) return '4:5';
    return '${width}x$height';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'width': width,
        'height': height,
        'duration_ms': durationMs,
        'checksum': checksum,
        'local_preview_url': localPreviewUrl,
        'media_type': mediaType.name,
        'created_at_utc': createdAtUtc.toIso8601String(),
      };

  factory MediaAsset.fromJson(Map<String, dynamic> json) => MediaAsset(
        id: json['id'] as String,
        fileName: json['file_name'] as String,
        mimeType: json['mime_type'] as String,
        sizeBytes: json['size_bytes'] as int,
        width: json['width'] as int?,
        height: json['height'] as int?,
        durationMs: json['duration_ms'] as int?,
        checksum: json['checksum'] as String?,
        localPreviewUrl: json['local_preview_url'] as String?,
        mediaType: MediaType.values.byName(json['media_type'] as String),
        createdAtUtc: DateTime.parse(json['created_at_utc'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MediaAsset && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
