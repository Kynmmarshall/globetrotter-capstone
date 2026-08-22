import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/models/models.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/services/voice_launcher.dart';
import 'package:trip_io/widgets/ai_formatted_text.dart';
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
  final VoiceRecorder _recorder = VoiceRecorder();
  final FlutterTts _tts = FlutterTts();
  bool _sending = false;
  bool _recording = false;
  bool _transcribing = false;
  bool _speaking = false;
  String? _error;
  Timer? _maxDurationTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _initTts();
  }

  void _initTts() {
    void resetSpeakingState() {
      if (mounted) setState(() => _speaking = false);
    }

    _tts.setStartHandler(() {
      if (mounted) setState(() => _speaking = true);
    });
    _tts.setCompletionHandler(resetSpeakingState);
    _tts.setCancelHandler(resetSpeakingState);
    _tts.setErrorHandler((_) => resetSpeakingState());
  }

  // Strips the [[Name|id]] destination-link markup (see ai_formatted_text.dart),
  // the **/__ bold and */_ italic markers, and emoji (Tia's system prompt
  // tells it to sprinkle these in - most TTS engines announce them by name,
  // e.g. "round pushpin", which sounds broken rather than natural) down to
  // plain words - reading the raw markup/glyphs aloud would sound broken.
  static final RegExp _emojiPattern = RegExp(
    '[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}\u{1F1E6}-\u{1F1FF}]',
    unicode: true,
  );

  String _spokenText(String content) {
    var text = content.replaceAllMapped(
      RegExp(r'\[\[([^\|\]]+)\|([^\]]+)\]\]'),
      (m) => m.group(1)!,
    );
    text = text.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*|__([^_]+)__'),
      (m) => m.group(1) ?? m.group(2) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'\*([^*]+)\*|_([^_\s][^_]*)_'),
      (m) => m.group(1) ?? m.group(2) ?? '',
    );
    text = text.replaceAll(_emojiPattern, '');
    text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
    return text;
  }

  // Best-effort: setVoice/getVoices are only implemented on Android, iOS and
  // macOS by the flutter_tts plugin - on Windows/Web this just no-ops via
  // the catch below and the platform's default voice plays instead.
  Future<void> _selectFemaleVoice(String languageCode) async {
    try {
      final voices = await _tts.getVoices;
      if (voices is! List) return;
      final localePrefix = languageCode == 'fr' ? 'fr' : 'en';
      for (final entry in voices) {
        if (entry is! Map) continue;
        final name = (entry['name'] ?? '').toString();
        final locale = (entry['locale'] ?? '').toString();
        if (!locale.toLowerCase().startsWith(localePrefix)) continue;
        final lowerName = name.toLowerCase();
        if (lowerName.contains('female') || lowerName.contains('woman')) {
          await _tts.setVoice({'name': name, 'locale': locale});
          return;
        }
      }
    } catch (_) {
      // Unsupported platform or malformed response - fall back to whatever
      // voice is already selected.
    }
  }

  Future<void> _speak(String content) async {
    final languageCode = widget.session.locale?.languageCode ?? 'en';
    await _tts.setLanguage(languageCode == 'fr' ? 'fr-FR' : 'en-US');
    await _selectFemaleVoice(languageCode);
    await _tts.speak(_spokenText(content));
  }

  Future<void> _toggleSound() async {
    final enabling = !widget.session.aiVoiceEnabled;
    await widget.session.setAiVoiceEnabled(enabling);
    if (!enabling && _speaking) {
      await _tts.stop();
    }
  }

  @override
  void dispose() {
    _maxDurationTimer?.cancel();
    unawaited(_tts.stop());
    _recorder.dispose();
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
      if (widget.session.aiVoiceEnabled) {
        unawaited(_speak(reply));
      }
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

  Future<void> _toggleRecording() async {
    final l10n = AppLocalizations.of(context)!;
    if (_recording) {
      _maxDurationTimer?.cancel();
      setState(() {
        _recording = false;
        _transcribing = true;
      });
      try {
        final result = await _recorder.stop();
        if (result == null || result.bytes.isEmpty) {
          throw Exception(l10n.aiChatVoiceEmptyError);
        }
        final text = await widget.session.transcribeVoiceMessage(
          result.bytes,
          result.filename,
        );
        if (mounted) _controller.text = text;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.aiChatVoiceFailedError)),
          );
        }
      } finally {
        if (mounted) setState(() => _transcribing = false);
      }
      return;
    }

    if (!await _recorder.ensurePermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiChatVoicePermissionDenied)),
        );
      }
      return;
    }
    await _recorder.start();
    if (!mounted) return;
    setState(() => _recording = true);
    _maxDurationTimer = Timer(const Duration(seconds: 90), _toggleRecording);
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
          // Only the assistant's own replies can contain [[Name|id]]
          // destination links (see ai.py's system prompt) - a user's own
          // message is shown as plain text so we never touch their literal
          // asterisks/etc.
          child: isUser
              ? Text(
                  message.content,
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.4,
                    fontSize: 13.5,
                  ),
                )
              : AiFormattedText(
                  content: message.content,
                  session: widget.session,
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
                icon: Icon(
                  widget.session.aiVoiceEnabled
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: Colors.white70,
                ),
                onPressed: _toggleSound,
                tooltip: widget.session.aiVoiceEnabled
                    ? l10n.aiChatVoiceMuteTooltip
                    : l10n.aiChatVoiceUnmuteTooltip,
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
                      onPressed: _transcribing ? null : _toggleRecording,
                      icon: _transcribing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            )
                          : Icon(
                              _recording ? Icons.stop_circle : Icons.mic_none,
                              color: _recording
                                  ? const Color(0xFFFF6B81)
                                  : Colors.white,
                            ),
                      tooltip: _recording
                          ? l10n.aiChatVoiceStopTooltip
                          : l10n.aiChatVoiceStartTooltip,
                    ),
                    IconButton(
                      onPressed: (_sending || _transcribing) ? null : _send,
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
