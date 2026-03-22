import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../database/post_database.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';
import '../widgets/app_page_routes.dart';
import 'post_detail_screen.dart';
import 'post_form_screen.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final _db = PostDatabase.instance;
  Future<List<Post>>? _postsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _postsFuture = _loadPosts();
    });
  }

  Future<void> _onPullRefresh() async {
    setState(() => _postsFuture = _loadPosts());
    await _postsFuture;
  }

  Future<List<Post>> _loadPosts() async {
    try {
      await _db.database;
      return _db.getAllPosts();
    } on DatabaseException catch (e) {
      throw Exception('Database error: $e');
    }
  }

  Widget _appBarTitle(BuildContext context, ColorScheme scheme, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Offline Posts',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
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
          body: SafeArea(
            child: FutureBuilder<List<Post>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                final loading = snapshot.connectionState == ConnectionState.waiting;
                final err = snapshot.hasError;
                final posts = snapshot.data ?? [];
                final empty = !loading && !err && posts.isEmpty;

                String subtitle;
                if (loading) {
                  subtitle = 'Preparing your library…';
                } else if (err) {
                  subtitle = 'Something went wrong';
                } else if (empty) {
                  subtitle = 'No drafts yet';
                } else {
                  subtitle = '${posts.length} saved locally';
                }

                return RefreshIndicator(
                  edgeOffset: 8,
                  onRefresh: loading ? () async {} : _onPullRefresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar.medium(
                        pinned: true,
                        floating: true,
                        backgroundColor: scheme.surfaceContainerLowest.withValues(
                          alpha: 0.72,
                        ),
                        surfaceTintColor: scheme.surfaceTint,
                        title: _appBarTitle(context, scheme, subtitle),
                        actions: [
                          IconButton.filledTonal(
                            tooltip: 'Refresh',
                            onPressed: loading
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    _refresh();
                                  },
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      if (loading)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _LoadingState(colorScheme: scheme),
                        )
                      else if (err)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _ErrorState(
                            message: snapshot.error.toString(),
                            onRetry: _refresh,
                          ),
                        )
                      else if (empty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(
                            onCreate: () async {
                              await Navigator.of(context).push(
                                AppPageRoutes.fadeSlide<void>(
                                  const PostFormScreen(),
                                ),
                              );
                              _refresh();
                            },
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final post = posts[index];
                                return _PostCard(
                                  post: post,
                                  index: index,
                                  onTap: () async {
                                    HapticFeedback.lightImpact();
                                    await Navigator.of(context).push(
                                      AppPageRoutes.fadeSlide<void>(
                                        PostDetailScreen(post: post),
                                      ),
                                    );
                                    _refresh();
                                  },
                                );
                              },
                              childCount: posts.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await Navigator.of(context).push(
                AppPageRoutes.fadeSlide<void>(const PostFormScreen()),
              );
              _refresh();
            },
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('New post'),
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.index,
    required this.onTap,
  });

  final Post post;
  final int index;
  final VoidCallback onTap;

  String get _initial {
    final t = post.title.trim();
    if (t.isEmpty) return '?';
    return t.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final id = post.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surface,
        elevation: 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: id != null ? 'post-avatar-$id' : 'post-avatar-new',
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Text(
                      _initial,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: id != null ? 'post-title-$id' : 'post-title-new',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            post.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Opening your library…',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 72,
              color: scheme.error,
            ),
            const SizedBox(height: 20),
            Text(
              'Could not open the database',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    scheme.primaryContainer,
                    scheme.secondaryContainer,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Icon(
                Icons.article_outlined,
                size: 56,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Your desk is clear',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Draft posts are saved on this device — no signal required. '
              'Tap below to write something worth keeping.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 28),
            FilledButton.tonalIcon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create first post'),
            ),
          ],
        ),
      ),
    );
  }
}
