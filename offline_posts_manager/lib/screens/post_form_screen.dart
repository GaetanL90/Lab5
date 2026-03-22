import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../database/post_database.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';

class PostFormScreen extends StatefulWidget {
  const PostFormScreen({super.key, this.post});

  final Post? post;

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _db = PostDatabase.instance;
  bool _saving = false;

  bool get _isEdit => widget.post != null;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    if (p != null) {
      _titleController.text = p.title;
      _bodyController.text = p.body;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    try {
      await _db.database;
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_isEdit) {
        final existing = widget.post!;
        await _db.updatePost(
          Post(
            id: existing.id,
            title: title,
            body: body,
            createdAt: existing.createdAt,
          ),
        );
      } else {
        await _db.insertPost(
          Post(
            title: title,
            body: body,
            createdAt: now,
          ),
        );
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
    } on DatabaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } on ArgumentError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? '$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
          appBar: AppBar(
            title: Text(_isEdit ? 'Edit post' : 'New post'),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).maybePop();
              },
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: scheme.surface.withValues(alpha: 0.9),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: scheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEdit ? 'Polish your draft' : 'Start writing',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Everything stays on this device until you change it.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Give it a headline',
                    prefixIcon: Icon(Icons.title_rounded, color: scheme.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter a title';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bodyController,
                  minLines: 10,
                  maxLines: 18,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Body',
                    alignLabelWithHint: true,
                    hintText: 'Tell the full story…',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 120),
                      child: Icon(Icons.notes_rounded, color: scheme.primary),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter a body';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: scheme.onPrimary,
                          ),
                        )
                      : Icon(_isEdit ? Icons.save_rounded : Icons.add_task_rounded),
                  label: Text(_saving ? 'Saving…' : (_isEdit ? 'Save changes' : 'Save post')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
