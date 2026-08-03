import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:movezy_user_app/AppNavigation/app_navigation.dart';
import 'package:movezy_user_app/Services/support_service.dart';

/// List of the customer's support tickets.
///
/// The app could raise tickets from three places but had no screen to read the
/// replies — every complaint was a one-way dead end. The endpoints existed all
/// along.
class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  List<SupportTicket> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await SupportService.getTickets();
      if (!mounted) return;
      setState(() {
        _tickets = t;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your tickets. Pull down to retry.';
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RESOLVED':
      case 'CLOSED':
        return HexColor("#1B7F45");
      case 'WAITING_FOR_USER':
        return HexColor("#C25A0C");
      case 'IN_PROGRESS':
        return HexColor("#2A5CD0");
      default:
        return HexColor("#607080");
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'WAITING_FOR_USER':
        return 'Your reply needed';
      case 'IN_PROGRESS':
        return 'Support is on it';
      case 'RESOLVED':
        return 'Resolved';
      case 'CLOSED':
        return 'Closed';
      default:
        return 'Open';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor("#F5F7F9"),
      appBar: AppBar(
        backgroundColor: HexColor("#FF6200"),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Support Tickets',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_tickets.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Icon(Icons.support_agent,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          _error ?? "You haven't raised any tickets yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _tickets.length,
                    itemBuilder: (_, i) {
                      final t = _tickets[i];
                      final when = t.lastMessageAt ?? t.createdAt;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: HexColor("#E1E6EF")),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          title: Text(
                            t.subject,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _statusColor(t.status)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusLabel(t.status),
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor(t.status)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (when != null)
                                  Text(
                                    DateFormat('dd MMM, hh:mm a')
                                        .format(when.toLocal()),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () async {
                            await pushTo(context,
                                SupportTicketThreadScreen(ticket: t));
                            _load(); // reflect any reply/close on return
                          },
                        ),
                      );
                    },
                  )),
      ),
    );
  }
}

/// A single ticket thread: the customer's messages and support's replies.
class SupportTicketThreadScreen extends StatefulWidget {
  final SupportTicket ticket;
  const SupportTicketThreadScreen({super.key, required this.ticket});

  @override
  State<SupportTicketThreadScreen> createState() =>
      _SupportTicketThreadScreenState();
}

class _SupportTicketThreadScreenState extends State<SupportTicketThreadScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<SupportMessage> _messages = [];
  late SupportTicket _ticket;
  bool _loading = true;
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _load();
    // No socket on the customer support channel, so poll while the thread is
    // open — an agent reply should appear without the user leaving and coming back.
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      final (t, msgs) = await SupportService.getThread(_ticket.id);
      if (!mounted) return;
      final grew = msgs.length != _messages.length;
      setState(() {
        _ticket = t;
        _messages = msgs;
        _loading = false;
      });
      if (grew) _scrollToEnd();
    } catch (_) {
      if (!mounted || quiet) return;
      setState(() => _loading = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);

    final (ok, msg) = await SupportService.reply(_ticket.id, text);
    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      _input.clear();
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isNotEmpty ? msg : 'Could not send your message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor("#F5F7F9"),
      appBar: AppBar(
        backgroundColor: HexColor("#FF6200"),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_ticket.ticketId.isNotEmpty ? _ticket.ticketId : 'Support',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_ticket.subject,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                if (_ticket.category.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(_ticket.category,
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Text(
                            "No replies yet. Our team will get back to you here.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(14),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _bubble(_messages[i]),
                      )),
          ),
          if (_ticket.isClosed)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Text(
                'This ticket is ${_ticket.status.toLowerCase()}. Raise a new one if you still need help.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
            )
          else
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Write a reply…',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                BorderSide(color: HexColor("#E1E6EF")),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _send,
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: HexColor("#FF6200"),
                          shape: BoxShape.circle,
                        ),
                        child: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send,
                                color: Colors.white, size: 18),
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

  Widget _bubble(SupportMessage m) {
    final mine = m.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: mine ? HexColor("#FF6200") : Colors.white,
          borderRadius: BorderRadius.circular(12).subtract(
            BorderRadius.only(
              bottomRight: Radius.circular(mine ? 12 : 0),
              bottomLeft: Radius.circular(mine ? 0 : 12),
            ),
          ),
          border: mine ? null : Border.all(color: HexColor("#E1E6EF")),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('Movezy Support',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: HexColor("#FF6200"))),
              ),
            Text(
              m.message,
              style: TextStyle(
                  fontSize: 13.5, color: mine ? Colors.white : Colors.black87),
            ),
            if (m.createdAt != null) ...[
              const SizedBox(height: 3),
              Text(
                DateFormat('dd MMM, hh:mm a').format(m.createdAt!.toLocal()),
                style: TextStyle(
                  fontSize: 9.5,
                  color: mine ? Colors.white70 : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
