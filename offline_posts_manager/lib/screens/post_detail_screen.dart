import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../database/post_database.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';
import '../widgets/app_page_routes.dart';
import 'post_form_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final Post post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _db = PostDatabase.instance;
  Future<Post?>? _postFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final id = widget.post.id;
    if (id == null) {
      throw StateError('Post id is null');
    }
    setState(() {
      _postFuture = _db.getPostById(id);
    });
  }

  Future<void> _confirmDelete() async {
    final id = widget.post.id;
    if (id == null) return;
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.delete_forever_rounded, color: scheme.error, size: 32),
        title: const Text('Delete this post?'),
        content: const Text(
          'This cannot be undone. The post will be removed from this device only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop(true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _db.database;
      final deleted = await _db.deletePost(id);
      if (!mounted) return;
      if (deleted == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post was not found.')),
        );
        return;
      }
      Navigator.of(context).pop();
    } on DatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(decoration: AppTheme.screenGradient(context)),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: FutureBuilder<Post?>(
            future: _postFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: scheme.primary),
                );
              }
              final post = snapshot.data;
              if (post == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'This post could not be read (missing or invalid data).',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              }
              final id = post.id;
              final date = DateTime.fromMillisecondsSinceEpoch(post.createdAt);
              final formatted = DateFormat.yMMMd().add_jm().format(date);

              return CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    pinned: true,
                    backgroundColor: scheme.surfaceContainerLowest.withValues(
                      alpha: 0.85,
                    ),
                    surfaceTintColor: scheme.surfaceTint,
                    leading: IconButton(
                      tooltip: 'Back',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    title: Text(
                      'Post',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    actions: [
                      IconButton.filledTonal(
                        tooltip: 'Edit',
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await Navigator.of(context).push(
                            AppPageRoutes.fadeSlide<void>(
                              PostFormScreen(post: post),
                            ),
                          );
                          _reload();
                        },
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: _confirmDelete,
                        icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (id != null)
                                Hero(
                                  tag: 'post-avatar-$id',
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: scheme.primaryContainer,
                                    foregroundColor: scheme.onPrimaryContainer,
                                    child: Text(
                                      _firstChar(post.title),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              if (id != null) const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (id != null)
                                      Hero(
                                        tag: 'post-title-$id',
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Text(
                                            post.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.2,
                                                  letterSpacing: -0.5,
                                                ),
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        post.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        Chip(
                                          avatar: Icon(
                                            Icons.schedule_rounded,
                                            size: 18,
                                            color: scheme.primary,
                                          ),
                                          label: Text(formatted),
                                          side: BorderSide(
                                            color: scheme.outlineVariant.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          backgroundColor: scheme.surfaceContainerHigh,
                                        ),
                                        Chip(
                                          avatar: Icon(
                                            Icons.offline_pin_rounded,
                                            size: 18,
                                            color: scheme.tertiary,
                                          ),
                                          label: const Text('Stored locally'),
                                          side: BorderSide(
                                            color: scheme.outlineVariant.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          backgroundColor: scheme.surfaceContainerHigh,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Material(
                            color: scheme.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: scheme.outlineVariant.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: SelectableText(
                                post.body,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: 1.55,
                                      fontSize: 16,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _firstChar(String title) {
    final t = title.trim();
    if (t.isEmpty) return '?';
    return t.substring(0, 1).toUpperCase();
  }
}
