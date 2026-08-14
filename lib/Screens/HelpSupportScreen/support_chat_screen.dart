import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

/// Support chat: a bot first, a person second.
///
/// The bot side is deliberately NOT an AI — it answers from the admin-managed
/// FAQ table (the same rows the Help screen shows), so every reply is something
/// support actually wrote. When that fails the customer, "Talk to an agent"
/// files a REAL support ticket and this same screen becomes the live thread:
/// messages go to POST /support/tickets/:id/messages and staff replies arrive
/// by polling the ticket. Tickets were previously the only channel, and the
/// client asked for chat-first with tickets kept underneath.
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

/// One bubble. Bot and agent render on the left, the customer on the right.
class _ChatEntry {
  final String text;
  final bool fromCustomer;
  final bool fromBot;
  const _ChatEntry(this.text, {this.fromCustomer = false, this.fromBot = false});
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final List<_ChatEntry> _entries = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// FAQ rows grouped by category, loaded once from the server.
  Map<String, List<Map<String, dynamic>>> _faqsByCategory = {};
  bool _loadingFaqs = true;

  /// Bot conversation state.
  String? _pickedCategory;

  /// Live-thread state. Null until the customer escalates.
  String? _ticketId;
  Timer? _pollTimer;
  int _seenMessageCount = 0;
  bool _sending = false;
  bool _ticketClosed = false;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Prefs.getString('token')}',
      };

  @override
  void initState() {
    super.initState();
    _entries.add(const _ChatEntry(
      'Hi! I can help with common questions right away. Pick a topic below — '
      'or talk to an agent at any time.',
      fromBot: true,
    ));
    _loadFaqs();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiUrls.baseUrlApi}/support/faqs'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List rows = data['data'] ?? [];
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final r in rows) {
          final cat = (r['category'] ?? 'general').toString();
          grouped.putIfAbsent(cat, () => []).add(Map<String, dynamic>.from(r));
        }
        if (mounted) setState(() { _faqsByCategory = grouped; _loadingFaqs = false; });
        return;
      }
    } catch (e) {
      debugPrint('Support chat FAQ load failed: $e');
    }
    // No FAQs — the bot has nothing to answer from; go straight to an agent
    // rather than presenting empty topic chips.
    if (mounted) setState(() => _loadingFaqs = false);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  // ─── Bot flow ───

  void _pickCategory(String cat) {
    setState(() {
      _pickedCategory = cat;
      _entries.add(_ChatEntry(_labelFor(cat), fromCustomer: true));
      _entries.add(const _ChatEntry('Here is what I can answer on that — tap a question:', fromBot: true));
    });
    _scrollToEnd();
  }

  void _pickQuestion(Map<String, dynamic> faq) {
    setState(() {
      _entries.add(_ChatEntry((faq['question'] ?? '').toString(), fromCustomer: true));
      _entries.add(_ChatEntry((faq['answer'] ?? '').toString(), fromBot: true));
      _entries.add(const _ChatEntry('Did that solve it? If not, pick another question or talk to an agent.', fromBot: true));
    });
    _scrollToEnd();
  }

  String _labelFor(String cat) =>
      cat.isEmpty ? cat : cat[0].toUpperCase() + cat.substring(1);

  // ─── Escalation to a live agent ───

  Future<void> _talkToAgent() async {
    if (_ticketId != null || _sending) return;
    setState(() => _sending = true);
    try {
      // The transcript so far becomes the ticket description, so the agent
      // reads what the bot already covered instead of re-asking.
      final transcript = _entries
          .map((e) => '${e.fromCustomer ? "Customer" : e.fromBot ? "Bot" : "Agent"}: ${e.text}')
          .join('\n');
      final res = await http.post(
        Uri.parse(ApiUrls.supportTicketsUrl),
        headers: _headers,
        body: jsonEncode({
          'category': _pickedCategory ?? 'other',
          'subject': 'Chat support${_pickedCategory != null ? ' — ${_labelFor(_pickedCategory!)}' : ''}',
          'message': transcript.isEmpty ? 'Customer requested chat support.' : transcript,
          // No priority sent — the server derives it from the category, so a
          // payment escalation lands HIGH instead of a hardcoded MEDIUM.
        }),
      );
      final body = jsonDecode(res.body);
      final id = body['data']?['ticket']?['_id'] ?? body['data']?['_id'];
      if (res.statusCode < 300 && id != null) {
        setState(() {
          _ticketId = id.toString();
          _entries.add(const _ChatEntry(
            "You're connected to our support team. Type your message below — "
            'replies land right here.',
            fromBot: true,
          ));
        });
        _startPolling();
      } else {
        _toast(body['message']?.toString() ?? "Couldn't reach support. Try again.");
      }
    } catch (e) {
      _toast("Couldn't reach support. Check your connection and try again.");
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollThread());
    _pollThread();
  }

  Future<void> _pollThread() async {
    final id = _ticketId;
    if (id == null) return;
    try {
      final res = await http.get(
        Uri.parse(ApiUrls.supportTicketDetailUrl(id)),
        headers: _headers,
      );
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body)['data'];
      final List messages = data?['messages'] ?? [];
      final status = (data?['ticket']?['status'] ?? '').toString();

      // Only append what we haven't rendered. The thread includes our own
      // messages too; those are already on screen the moment they were sent,
      // so only non-USER senders are appended from the poll.
      if (messages.length > _seenMessageCount) {
        final fresh = messages.sublist(_seenMessageCount);
        _seenMessageCount = messages.length;
        var added = false;
        for (final m in fresh) {
          if ((m['senderType'] ?? '') != 'USER') {
            _entries.add(_ChatEntry((m['message'] ?? '').toString()));
            added = true;
          }
        }
        if (added && mounted) {
          setState(() {});
          _scrollToEnd();
        }
      }

      if (status == 'CLOSED' && !_ticketClosed && mounted) {
        setState(() {
          _ticketClosed = true;
          _entries.add(const _ChatEntry(
              'This conversation was closed. Start a new chat any time.',
              fromBot: true));
        });
        _pollTimer?.cancel();
        _scrollToEnd();
      }
    } catch (e) {
      debugPrint('Support chat poll failed: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _input.text.trim();
    final id = _ticketId;
    if (text.isEmpty || id == null || _sending || _ticketClosed) return;
    setState(() {
      _sending = true;
      _entries.add(_ChatEntry(text, fromCustomer: true));
      _input.clear();
    });
    _scrollToEnd();
    try {
      final res = await http.post(
        Uri.parse(ApiUrls.supportTicketReplyUrl(id)),
        headers: _headers,
        body: jsonEncode({'message': text}),
      );
      if (res.statusCode >= 300) {
        _toast('Message not delivered — try again.');
      } else {
        // Our message is now in the thread; account for it so the poll doesn't
        // double-append the next agent reply.
        _seenMessageCount += 1;
      }
    } catch (_) {
      _toast('Message not delivered — check your connection.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));
  }

  // ─── UI ───

  @override
  Widget build(BuildContext context) {
    final live = _ticketId != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          commonAppBar(
            height: 100,
            context: context,
            child: Container(
              padding: const EdgeInsets.only(top: 50),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.only(left: 16),
                      width: 40,
                      height: 35,
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(live ? 'Support Chat' : 'Movezy Assistant',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (live && !_ticketClosed)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(children: const [
                        Icon(Icons.circle, size: 9, color: Color(0xFF7CFC9A)),
                        SizedBox(width: 5),
                        Text('Live', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ]),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              itemCount: _entries.length + 1,
              itemBuilder: (context, i) {
                if (i < _entries.length) return _bubble(_entries[i]);
                // Trailing interactive block under the last bubble.
                return _interactionArea();
              },
            ),
          ),
          _composer(live),
        ],
      ),
    );
  }

  Widget _bubble(_ChatEntry e) {
    final mine = e.fromCustomer;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: mine ? AppColors.appColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 3),
            bottomRight: Radius.circular(mine ? 3 : 14),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(e.text,
            style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: mine ? Colors.white : Colors.black87)),
      ),
    );
  }

  /// The chips the bot offers at the current step. Hidden once live — the
  /// conversation belongs to the agent then.
  Widget _interactionArea() {
    if (_ticketId != null) return const SizedBox(height: 4);
    if (_loadingFaqs) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final chips = <Widget>[];
    if (_pickedCategory == null) {
      for (final cat in _faqsByCategory.keys) {
        chips.add(_chip(_labelFor(cat), () => _pickCategory(cat)));
      }
    } else {
      for (final faq in _faqsByCategory[_pickedCategory] ?? const []) {
        chips.add(_chip((faq['question'] ?? '').toString(), () => _pickQuestion(faq)));
      }
      chips.add(_chip('← Other topics', () {
        setState(() => _pickedCategory = null);
        _scrollToEnd();
      }, outlined: true));
    }

    chips.add(_chip(
      _sending ? 'Connecting…' : 'Talk to an agent',
      _talkToAgent,
      accent: true,
    ));

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _chip(String label, VoidCallback onTap,
      {bool accent = false, bool outlined = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: accent
              ? AppColors.appColor
              : outlined
                  ? Colors.transparent
                  : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: accent ? AppColors.appColor : const Color(0xFFE3E3E3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: accent ? Colors.white : Colors.black87)),
      ),
    );
  }

  /// Text input — enabled only in live mode. The bot is tap-driven, and an
  /// enabled box implying "type to the bot" would just funnel free text into
  /// nothing.
  Widget _composer(bool live) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).viewPadding.bottom),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              enabled: live && !_ticketClosed,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _ticketClosed
                    ? 'Conversation closed'
                    : live
                        ? 'Type a message…'
                        : 'Tap "Talk to an agent" to type',
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF3F3F3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: live && !_ticketClosed ? _sendMessage : null,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: live && !_ticketClosed ? AppColors.appColor : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: _sending && live
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
