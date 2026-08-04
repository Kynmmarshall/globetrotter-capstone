import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/glass_panel.dart';
import 'package:trip_io/widgets/session_expired_card.dart';

/// Opens the AI chat as a draggable sheet over whatever screen the user is
/// currently on - same pattern as [showCommentsSheet] - instead of a
/// dedicated nav tab. That way asking the AI something never means losing
/// your place in whatever you were browsing.
Future<void> showAiChatSheet(
  BuildContext context, {
  required SessionController session,
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
                child: AiChatSheet(
                  session: session,
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

class AiChatSheet extends StatefulWidget {
  const AiChatSheet({
    super.key,
    required this.session,
    required this.scrollController,
  });

  final SessionController session;
  final ScrollController scrollController;

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await widget.session.loadChatHistory();
    if (!mounted || history.isEmpty) return;
    setState(() => _messages.addAll(history));
    _scrollToBottom();
  }

  Future<void> _send({String? presetText}) async {
    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _controller.clear();
      _sending = true;
      _error = null;
    });
    _scrollToBottom();
    try {
      final reply = await widget.session.aiChat(_messages);
      setState(
        () => _messages.add(ChatMessage(role: 'assistant', content: reply)),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      // Persisting also caps the history to a rolling window, so the
      // conversation feels continuous without every reply resending an
      // ever-growing transcript (and its token cost) to Groq.
      final trimmed = await widget.session.saveChatHistory(_messages);
      if (mounted && trimmed.length != _messages.length) {
        setState(() {
          _messages
            ..clear()
            ..addAll(trimmed);
        });
      }
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.scrollController.hasClients) return;
      widget.scrollController.animateTo(
        widget.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final suggestions = [
      l10n.aiChatSuggestion1,
      l10n.aiChatSuggestion2,
      l10n.aiChatSuggestion3,
      l10n.aiChatSuggestion4,
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.aiChatEmptyState,
              style: const TextStyle(color: Colors.white70, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.aiChatSuggestionsLabel.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in suggestions)
                  ActionChip(
                    label: Text(
                      suggestion,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                      ),
                    ),
                    backgroundColor: const Color(0xFF13303B),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    onPressed: _sending
                        ? null
                        : () => _send(presetText: suggestion),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(BuildContext context, ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            // Solid, tinted bubbles instead of near-invisible frosted white -
            // chat text needs to stay legible over any photo background.
            color: isUser
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFF13253A).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUser
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: Colors.white,
              height: 1.4,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authError = _error != null && isAuthError(_error!);

    return Column(
      children: [
        // Drag handle - ties the message list's own scrolling to the
        // sheet's drag-to-resize/dismiss gesture, same as the comments sheet.
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiChatTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aiChatSubtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
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
          child: _messages.isEmpty
              ? _buildEmptyState(context, l10n)
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _messages.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 10, left: 4),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      );
                    }
                    return _buildBubble(context, _messages[index]);
                  },
                ),
        ),
        if (authError)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SessionExpiredCard(session: widget.session),
          )
        else ...[
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _error!.contains('not configured')
                    ? l10n.aiChatNotConfigured
                    : l10n.aiChatErrorMessage(_error!),
                style: TextStyle(color: Colors.red.shade100, fontSize: 12.5),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GlassPanel(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: Colors.white,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: l10n.aiChatInputHint,
                          hintStyle: const TextStyle(color: Colors.white60),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
