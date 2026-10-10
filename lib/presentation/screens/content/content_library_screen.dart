import 'package:flutter/material.dart';

import 'package:no5ocial/core/theme/app_colors.dart';
import 'package:no5ocial/core/theme/app_typography.dart';
import 'package:no5ocial/core/utils/date_formatter.dart';
import 'package:no5ocial/domain/enums/publish_status.dart';
import 'package:no5ocial/domain/models/content_post.dart';
import 'package:no5ocial/presentation/screens/composer/composer_screen.dart';
import 'package:no5ocial/presentation/state/app_state.dart';
import 'package:no5ocial/presentation/widgets/brand_badge.dart';
import 'package:no5ocial/presentation/widgets/platform_icon_chip.dart';
import 'package:no5ocial/presentation/widgets/status_badge.dart';

class ContentLibraryScreen extends StatelessWidget {
  final AppState appState;

  const ContentLibraryScreen({super.key, required this.appState});

  void _openComposer(BuildContext context, [ContentPost? post]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComposerScreen(appState: appState, initialPost: post),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ContentPost post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post Draft?'),
        content: Text('Are you sure you want to delete "${post.title}"? This will cancel associated jobs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              appState.deletePost(post.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post draft deleted.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final posts = appState.filteredPosts;
        final brands = appState.brands;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Content Library'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'New Post',
                onPressed: () => _openComposer(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter header
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search posts, captions, campaigns, or tags...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                      style: AppTypography.bodyMedium,
                      onChanged: (val) => appState.setSearchQuery(val),
                    ),
                    const SizedBox(height: 10),
                    // Brand Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          BrandBadge(
                            brand: null,
                            isSelected: appState.selectedBrandFilterId == null,
                            onTap: () => appState.setBrandFilter(null),
                          ),
                          const SizedBox(width: 8),
                          ...brands.map((b) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: BrandBadge(
                                  brand: b,
                                  isSelected: appState.selectedBrandFilterId == b.id,
                                  onTap: () => appState.setBrandFilter(b.id),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status Filter Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusFilterChip('All Statuses', null),
                          _buildStatusFilterChip('Drafts', PublishJobStatus.draft),
                          _buildStatusFilterChip('Scheduled', PublishJobStatus.scheduled),
                          _buildStatusFilterChip('Published', PublishJobStatus.published),
                          _buildStatusFilterChip('Action Needed', PublishJobStatus.actionRequired),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Post cards list
              Expanded(
                child: posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_open_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No posts match your filters.',
                              style: AppTypography.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try adjusting the search query or brand filter.',
                              style: AppTypography.bodySecondary.copyWith(fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _openComposer(context),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Create New Post'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: posts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final post = posts[index];
                          return _buildPostCard(context, post);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusFilterChip(String label, PublishJobStatus? status) {
    final isSelected = appState.selectedStatusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        selected: isSelected,
        onSelected: (_) => appState.setStatusFilter(status),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, ContentPost post) {
    final brand = appState.getBrandById(post.brandId);
    final jobs = appState.getJobsForPost(post.id);

    return InkWell(
      onTap: () => _openComposer(context, post),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Brand & Status badge & actions
            Row(
              children: [
                if (brand != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      brand.name,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (post.campaign != null) ...[
                  const SizedBox(width: 6),
                  Text('•  ${post.campaign}', style: AppTypography.labelSmall),
                ],
                const Spacer(),
                StatusBadge(status: post.status),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'edit') _openComposer(context, post);
                    if (val == 'delete') _confirmDelete(context, post);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit in Composer')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Draft')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title & Caption snippet
            Text(
              post.title,
              style: AppTypography.titleMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              post.defaultCaption,
              style: AppTypography.bodySecondary.copyWith(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Attached destinations chip row
            if (post.destinationAccountIds.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: post.destinationAccountIds.map((accId) {
                  final acc = appState.getAccountById(accId);
                  if (acc == null) return const SizedBox.shrink();
                  final job = jobs.where((j) => j.socialAccountId == accId).firstOrNull;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlatformIconChip(account: acc, isCompact: true),
                      if (job != null) ...[
                        const SizedBox(width: 4),
                        StatusBadge(status: job.status, isManual: job.isManual, isCompact: true),
                      ],
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // Footer metadata
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Updated: ${DateFormatter.formatRelative(post.updatedAtUtc)}',
                  style: AppTypography.bodySecondary.copyWith(fontSize: 11, color: AppColors.textMuted),
                ),
                if (post.mediaAssetIds.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.attach_file, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Text(
                    '${post.mediaAssetIds.length} media',
                    style: AppTypography.bodySecondary.copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
