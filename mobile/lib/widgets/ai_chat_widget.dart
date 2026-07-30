import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/constants.dart';
import 'package:mobile/services/ai_service.dart';
import 'package:mobile/services/user_session.dart';

/// A bottom-sheet chat widget that lets the user converse with the AI
/// assistant about their current screen, itinerary, or any Nepal travel topic.
///
/// Editing and proposal features have been removed — this is chat-only.
class AIChatWidget extends StatefulWidget {
  /// Name of the screen that opened this widget (e.g. 'explore', 'plan',
  /// 'saved_itinerary_detail').  Sent to the backend so the LLM can give
  /// contextually relevant answers.
  final String screenContext;

  /// Optional extra data from the current screen (search query, origin,
  /// destination, etc.).  Serialised and included in the system prompt.
  final Map<String, dynamic>? screenData;

  /// The itinerary the user is currently viewing, if any.
  final Map<String, dynamic>? itineraryContext;

  const AIChatWidget({
    super.key,
    required this.screenContext,
    this.screenData,
    this.itineraryContext,
  });

  @override
  State<AIChatWidget> createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget> {
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content':
          'Namaste! I\'m your YatraSathi travel assistant. Ask me anything about Nepal — places, routes, seasons, permits, food, culture, or your itinerary.',
    }
  ];

  bool _loading = false;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _sessionId;

  String _getSessionId() {
    _sessionId ??=
        '${AIService.generateSessionId()}_${UserSession.loggedInUser ?? "guest"}';
    return _sessionId!;
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _loading) return;

    _inputController.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _scrollToBottom();

    try {
      // Build itinerary context: prefer explicitly provided, else first saved
      Map<String, dynamic>? itCtx = widget.itineraryContext;
      if (itCtx == null && UserSession.savedItineraries.isNotEmpty) {
        final first = UserSession.savedItineraries.first;
        itCtx = {
          'id': first.id,
          'title': first.title,
          'origin': first.from,
          'destination': first.to,
          'days': first.days,
          'itinerary': first.itinerary,
        };
      }

      // Build lightweight saved-itineraries list
      final savedList = UserSession.savedItineraries.map((it) => {
            'id': it.id,
            'title': it.title,
            'origin': it.from,
            'destination': it.to,
            'days': it.days,
            'budget': it.budget,
            'pace': it.pace,
          }).toList();

      final data = await AIService.chat(
        sessionId: _getSessionId(),
        userId: UserSession.loggedInUser,
        message: text,
        screenContext: widget.screenContext,
        screenData: widget.screenData,
        itineraryContext: itCtx,
        createdItineraries: savedList,
      );

      final reply = data['response_text'] as String? ?? '';
      setState(() => _messages.add({'role': 'assistant', 'content': reply}));
    } catch (e) {
      setState(() => _messages.add({
            'role': 'assistant',
            'content':
                'Sorry, I couldn\'t reach the AI service right now. '
                'Make sure the backend is running and GROQ_API_KEY is set.',
          }));
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          // ── Drag handle ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: kGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.assistant, color: kOrange, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YatraSathi Assistant',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: kDark)),
                    Text('Powered by Groq AI',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: kGray,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: kDark),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: kBorder, height: 1),

          // ── Messages ──────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isUser ? kOrange : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border:
                          isUser ? null : Border.all(color: kBorder),
                    ),
                    child: Text(
                      msg['content'] as String? ?? '',
                      style: GoogleFonts.inter(
                        color: isUser ? Colors.white : kDark,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Typing indicator ──────────────────────────────────────────
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: kOrange),
                  ),
                  const SizedBox(width: 10),
                  Text('Thinking...',
                      style:
                          GoogleFonts.inter(color: kGray, fontSize: 13)),
                ],
              ),
            ),

          // ── Input bar ─────────────────────────────────────────────────
          const Divider(color: kBorder, height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Ask about Nepal, your itinerary...',
                        hintStyle:
                            GoogleFonts.inter(color: kGray, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: kBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: kBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: kOrange, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _loading ? kBorder : kOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
