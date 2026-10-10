import 'package:no5ocial/data/local/seed_data.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/domain/models/media_asset.dart';
import 'package:no5ocial/domain/models/post_variant.dart';

abstract class PostRepository {
  List<ContentPost> getAllPosts();
  List<ContentPost> getPostsByBrand(String brandId);
  List<ContentPost> getPostsByStatus(PublishJobStatus status);
  ContentPost? getPostById(String id);
  void savePost(ContentPost post);
  void deletePost(String id);

  // Variants
  List<PostVariant> getVariantsForPost(String postId);
  PostVariant? getVariant(String postId, String accountId);
  void saveVariant(PostVariant variant);

  // Media
  List<MediaAsset> getAllMediaAssets();
  MediaAsset? getMediaAssetById(String id);
  void saveMediaAsset(MediaAsset asset);
}

class InMemoryPostRepository implements PostRepository {
  final Map<String, ContentPost> _posts = {};
  final Map<String, PostVariant> _variants = {};
  final Map<String, MediaAsset> _media = {};

  InMemoryPostRepository({
    List<ContentPost>? initialPosts,
    List<PostVariant>? initialVariants,
    List<MediaAsset>? initialMedia,
  }) {
    for (final post in (initialPosts ?? SeedData.initialPosts)) {
      _posts[post.id] = post;
    }
    for (final variant in (initialVariants ?? SeedData.initialVariants)) {
      _variants[variant.id] = variant;
    }
    for (final media in (initialMedia ?? SeedData.initialMediaAssets)) {
      _media[media.id] = media;
    }
  }

  @override
  List<ContentPost> getAllPosts() {
    final list = _posts.values.toList();
    list.sort((a, b) => b.updatedAtUtc.compareTo(a.updatedAtUtc));
    return list;
  }

  @override
  List<ContentPost> getPostsByBrand(String brandId) =>
      _posts.values.where((p) => p.brandId == brandId).toList();

  @override
  List<ContentPost> getPostsByStatus(PublishJobStatus status) =>
      _posts.values.where((p) => p.status == status).toList();

  @override
  ContentPost? getPostById(String id) => _posts[id];

  @override
  void savePost(ContentPost post) {
    _posts[post.id] = post;
  }

  @override
  void deletePost(String id) {
    _posts.remove(id);
    _variants.removeWhere((_, v) => v.contentPostId == id);
  }

  @override
  List<PostVariant> getVariantsForPost(String postId) =>
      _variants.values.where((v) => v.contentPostId == postId).toList();

  @override
  PostVariant? getVariant(String postId, String accountId) {
    for (final variant in _variants.values) {
      if (variant.contentPostId == postId && variant.socialAccountId == accountId) {
        return variant;
      }
    }
    return null;
  }

  @override
  void saveVariant(PostVariant variant) {
    _variants[variant.id] = variant;
  }

  @override
  List<MediaAsset> getAllMediaAssets() => _media.values.toList();

  @override
  MediaAsset? getMediaAssetById(String id) => _media[id];

  @override
  void saveMediaAsset(MediaAsset asset) {
    _media[asset.id] = asset;
  }
}
