import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/glass_panel.dart';

/// Opens the comment thread as a draggable sheet that slides up over the
/// current screen (TikTok/YouTube Shorts style) instead of living inline in
/// the page. Call this from a "Comments" button.
Future<void> showCommentsSheet(
  BuildContext context, {
  required SessionController session,
  required String destinationId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1A24).withValues(alpha: 0.96),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                child: CommentsSection(
                  session: session,
                  destinationId: destinationId,
                  scrollController: scrollController,
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Reddit-style comment thread for a destination: post, reply at any depth,
/// upvote/downvote. Rendered inside the draggable sheet [showCommentsSheet]
/// opens - [scrollController] is the sheet's own controller, so dragging the
/// list and dragging the sheet itself are the same gesture, same as
/// TikTok/YouTube Shorts' comment drawers.
class CommentsSection extends StatefulWidget {
  const CommentsSection({
    super.key,
    required this.session,
    required this.destinationId,
    required this.scrollController,
  });

  final SessionController session;
  final String destinationId;
  final ScrollController scrollController;

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  List<Comment>? _comments;
  String? _error;
  bool _loading = true;
  bool _posting = false;
  final TextEditingController _composerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final comments = await widget.session.comments(widget.destinationId);
      if (!mounted) return;
      setState(() => _comments = comments);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _postTopLevel() async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      final comment = await widget.session.postComment(
        widget.destinationId,
        text,
      );
      setState(() {
        _comments = [comment, ...?_comments];
        _composerController.clear();
      });
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }

  List<Comment> _mapTree(
    List<Comment> nodes,
    bool Function(Comment) match,
    Comment Function(Comment) transform,
  ) {
    return nodes.map((c) {
      if (match(c)) return transform(c);
      if (c.replies.isNotEmpty) {
        c.replies = _mapTree(c.replies, match, transform);
      }
      return c;
    }).toList();
  }

  int _totalCount(List<Comment> nodes) {
    var total = 0;
    for (final c in nodes) {
      total += 1 + _totalCount(c.replies);
    }
    return total;
  }

  void _onReplyPosted(String parentId, Comment reply) {
    setState(() {
      _comments = _mapTree(_comments ?? [], (c) => c.id == parentId, (c) {
        c.replies = [...c.replies, reply];
        return c;
      });
    });
  }

  void _onVoted(String commentId, Comment updated) {
    setState(() {
      _comments = _mapTree(
        _comments ?? [],
        (c) => c.id == commentId,
        (c) => c.withVote(score: updated.score, userVote: updated.userVote),
      );
    });
  }

  void _onEdited(String commentId, Comment updated) {
    setState(() {
      _comments = _mapTree(
        _comments ?? [],
        (c) => c.id == commentId,
        (c) => c.withText(updated.text),
      );
    });
  }

  List<Comment> _removeFromTree(List<Comment> nodes, String commentId) {
    return nodes.where((c) => c.id != commentId).map((c) {
      if (c.replies.isNotEmpty) {
        c.replies = _removeFromTree(c.replies, commentId);
      }
      return c;
    }).toList();
  }

  void _onDeleted(String commentId) {
    setState(() => _comments = _removeFromTree(_comments ?? [], commentId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final comments = _comments ?? [];

    return Column(
      children: [
        // Drag handle - visually ties the list's own scrolling to the
        // sheet's drag-to-resize/dismiss gesture.
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 10),
          child: Row(
            children: [
              const Icon(Icons.forum_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comments.isEmpty
                      ? l10n.commentsTitle
                      : '${l10n.commentsTitle} (${_totalCount(comments)})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: MaterialLocalizations.of(context).closeButtonLabel,
              ),
            ],
          ),
        ),
        Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.commentsLoadError(_error!),
                      style: TextStyle(color: Colors.red.shade100),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : comments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.commentsEmpty,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: comments.length,
                  itemBuilder: (context, index) => _CommentTile(
                    comment: comments[index],
                    session: widget.session,
                    destinationId: widget.destinationId,
                    depth: 0,
                    onReplyPosted: _onReplyPosted,
                    onVoted: _onVoted,
                    onEdited: _onEdited,
                    onDeleted: _onDeleted,
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: GlassPanel(
              style: GlassPanelStyle.flat,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composerController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: l10n.commentsInputHint,
                        hintStyle: const TextStyle(color: Colors.white60),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.commentsPostButton,
                    onPressed: _posting ? null : _postTopLevel,
                    icon: _posting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.session,
    required this.destinationId,
    required this.depth,
    required this.onReplyPosted,
    required this.onVoted,
    required this.onEdited,
    required this.onDeleted,
  });

  final Comment comment;
  final SessionController session;
  final String destinationId;
  final int depth;
  final void Function(String parentId, Comment reply) onReplyPosted;
  final void Function(String commentId, Comment updated) onVoted;
  final void Function(String commentId, Comment updated) onEdited;
  final void Function(String commentId) onDeleted;

  // How long after posting a comment its author may still edit/delete it -
  // must match the backend's COMMENT_EDIT_WINDOW
  // (recommendation_service/app/crud.py) or this button would stay
  // enabled/disabled out of sync with what the server actually allows.
  static const editWindow = Duration(minutes: 5);

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplyBox = false;
  bool _posting = false;
  bool _voting = false;
  bool _editing = false;
  bool _saving = false;
  bool _deleting = false;
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _editController = TextEditingController();

  bool get _isOwnComment => widget.comment.username == widget.session.username;

  // Evaluated at build/interaction time rather than kept live-ticking with
  // a Timer - good enough since the backend is the real source of truth
  // for the deadline anyway (a stale-but-still-shown button just gets a
  // 403 from _saveEdit/_delete, surfaced the same way any other failure is).
  bool get _withinEditWindow {
    final createdAt = widget.comment.createdAt;
    if (createdAt == null) return false;
    return DateTime.now().toUtc().difference(createdAt.toUtc()) <
        _CommentTile.editWindow;
  }

  bool get _canModify => _isOwnComment && _withinEditWindow;

  @override
  void dispose() {
    _replyController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }

  void _startEdit() {
    _editController.text = widget.comment.text;
    setState(() => _editing = true);
  }

  Future<void> _saveEdit() async {
    final text = _editController.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.session.editComment(widget.comment.id, text);
      widget.onEdited(widget.comment.id, updated);
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.commentDeleteConfirmTitle),
        content: Text(l10n.commentDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: Text(l10n.commentDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.session.deleteComment(widget.comment.id);
      widget.onDeleted(widget.comment.id);
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _vote(String direction) async {
    if (_voting) return;
    // Tapping an already-active vote button clears it, same as Reddit.
    final next = widget.comment.userVote == direction ? 'none' : direction;
    setState(() => _voting = true);
    try {
      final updated = await widget.session.voteComment(widget.comment.id, next);
      widget.onVoted(widget.comment.id, updated);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<void> _postReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      final reply = await widget.session.postComment(
        widget.destinationId,
        text,
        parentId: widget.comment.id,
      );
      widget.onReplyPosted(widget.comment.id, reply);
      _replyController.clear();
      if (mounted) setState(() => _showReplyBox = false);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Widget _voteButton(
    IconData icon, {
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 16,
          color: active
              ? Theme.of(context).colorScheme.primary
              : Colors.white54,
        ),
      ),
    );
  }

  // Kept deliberately unlocalized: short relative-time abbreviations like
  // this read fine in both English and French and translating "m"/"h"/"d"
  // would add complexity for no real clarity gain.
  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Indentation is capped so very deep threads don't push replies off a
    // narrow phone screen - the data itself still nests without limit.
    final indent = widget.depth.clamp(0, 6) * 14.0;

    return Padding(
      padding: EdgeInsets.only(left: indent, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: _deleting ? 0.5 : 1,
            child: IgnorePointer(
              ignoring: _deleting,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // A solid, tinted card instead of the near-invisible frosted
                  // white used for structural panels - comment text needs to
                  // stay legible over any photo background, not just blend in.
                  color: const Color(0xFF13253A).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.comment.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (widget.comment.createdAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _relativeTime(widget.comment.createdAt!),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (_canModify && !_editing)
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_horiz,
                              color: Colors.white54,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            color: const Color(0xFF13253A),
                            onSelected: (value) => value == 'edit'
                                ? _startEdit()
                                : _confirmDelete(),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(
                                  l10n.commentEditButton,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  l10n.commentDeleteButton,
                                  style: TextStyle(color: Colors.red.shade200),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (_editing) ...[
                      TextField(
                        controller: _editController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                        ),
                        cursorColor: Colors.white,
                        minLines: 1,
                        maxLines: 6,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.08),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() => _editing = false),
                            child: Text(
                              l10n.cancelButton,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            onPressed: _saving ? null : _saveEdit,
                            child: _saving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.saveButton),
                          ),
                        ],
                      ),
                    ] else
                      Text(
                        widget.comment.text,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _voteButton(
                          widget.comment.userVote == 'up'
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          active: widget.comment.userVote == 'up',
                          onTap: () => _vote('up'),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.comment.score}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _voteButton(
                          widget.comment.userVote == 'down'
                              ? Icons.thumb_down
                              : Icons.thumb_down_outlined,
                          active: widget.comment.userVote == 'down',
                          onTap: () => _vote('down'),
                        ),
                        const SizedBox(width: 14),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showReplyBox = !_showReplyBox),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.commentsReplyButton,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showReplyBox) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              autofocus: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              cursorColor: Colors.white,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                hintText: l10n.commentsInputHint,
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.commentsPostButton,
                            onPressed: _posting ? null : _postReply,
                            icon: _posting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white70,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          for (final reply in widget.comment.replies)
            _CommentTile(
              comment: reply,
              session: widget.session,
              destinationId: widget.destinationId,
              depth: widget.depth + 1,
              onReplyPosted: widget.onReplyPosted,
              onVoted: widget.onVoted,
              onEdited: widget.onEdited,
              onDeleted: widget.onDeleted,
            ),
        ],
      ),
    );
  }
}
