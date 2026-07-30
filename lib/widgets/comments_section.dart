import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';

/// Reddit-style comment thread for a destination: post, reply at any depth,
/// upvote/downvote. Lives at the bottom of DestinationDetailPage.
class CommentsSection extends StatefulWidget {
  const CommentsSection({super.key, required this.session, required this.destinationId});

  final SessionController session;
  final String destinationId;

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
      final comment = await widget.session.postComment(widget.destinationId, text);
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

  List<Comment> _mapTree(List<Comment> nodes, bool Function(Comment) match, Comment Function(Comment) transform) {
    return nodes.map((c) {
      if (match(c)) return transform(c);
      if (c.replies.isNotEmpty) {
        c.replies = _mapTree(c.replies, match, transform);
      }
      return c;
    }).toList();
  }

  void _onReplyPosted(String parentId, Comment reply) {
    setState(() {
      _comments = _mapTree(
        _comments ?? [],
        (c) => c.id == parentId,
        (c) {
          c.replies = [...c.replies, reply];
          return c;
        },
      );
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

  Widget _glassPanel({required Widget child, EdgeInsets? padding, BorderRadius? borderRadius}) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(padding: padding ?? const EdgeInsets.all(12), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final comments = _comments ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.forum_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              l10n.commentsTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _glassPanel(
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()))
        else if (_error != null)
          Text(l10n.commentsLoadError(_error!), style: TextStyle(color: Colors.red.shade100))
        else if (comments.isEmpty)
          Text(l10n.commentsEmpty, style: const TextStyle(color: Colors.white70))
        else
          Column(
            children: comments
                .map((c) => _CommentTile(
                      comment: c,
                      session: widget.session,
                      destinationId: widget.destinationId,
                      depth: 0,
                      onReplyPosted: _onReplyPosted,
                      onVoted: _onVoted,
                    ))
                .toList(),
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
  });

  final Comment comment;
  final SessionController session;
  final String destinationId;
  final int depth;
  final void Function(String parentId, Comment reply) onReplyPosted;
  final void Function(String commentId, Comment updated) onVoted;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplyBox = false;
  bool _posting = false;
  bool _voting = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
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
      final reply = await widget.session.postComment(widget.destinationId, text, parentId: widget.comment.id);
      widget.onReplyPosted(widget.comment.id, reply);
      _replyController.clear();
      if (mounted) setState(() => _showReplyBox = false);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Widget _voteButton(IconData icon, {required bool active, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: active ? Theme.of(context).colorScheme.primary : Colors.white54),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // A solid, tinted card instead of the near-invisible frosted
              // white used for structural panels - comment text needs to
              // stay legible over any photo background, not just blend in.
              color: const Color(0xFF13253A).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.comment.username,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    if (widget.comment.createdAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(widget.comment.createdAt!),
                        style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.comment.text,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _voteButton(Icons.arrow_upward, active: widget.comment.userVote == 'up', onTap: () => _vote('up')),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.comment.score}',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    const SizedBox(width: 4),
                    _voteButton(Icons.arrow_downward, active: widget.comment.userVote == 'down', onTap: () => _vote('down')),
                    const SizedBox(width: 14),
                    TextButton(
                      onPressed: () => setState(() => _showReplyBox = !_showReplyBox),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.commentsReplyButton,
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
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
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          cursorColor: Colors.white,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.08),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            hintText: l10n.commentsInputHint,
                            hintStyle: const TextStyle(color: Colors.white54),
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                              )
                            : const Icon(Icons.send, size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ],
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
            ),
        ],
      ),
    );
  }
}
