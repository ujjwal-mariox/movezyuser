import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

/// Tap-to-send lines above the chat box ("Where are you right now?" …).
/// Admin-managed on the server; hidden while loading or when there are none.
class QuickRepliesBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  const QuickRepliesBar({super.key, required this.onSend});

  @override
  State<QuickRepliesBar> createState() => _QuickRepliesBarState();
}

class _QuickRepliesBarState extends State<QuickRepliesBar> {
  static List<String>? _cached;
  List<String> _replies = _cached ?? const [];

  @override
  void initState() {
    super.initState();
    if (_cached == null) _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse(ApiUrls.chatQuickRepliesUrl),
        headers: {'Authorization': 'Bearer ${Prefs.getString('token')}'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      final data = body is Map ? body['data'] : null;
      final list = data is Map ? data['replies'] : null;
      if (list is! List) return;
      final texts = list
          .map((e) => (e is Map ? e['text'] : e)?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
      _cached = texts;
      if (mounted) setState(() => _replies = texts);
    } catch (_) {
      // Chips are a convenience; typing still works.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_replies.isEmpty) return const SizedBox.shrink();
    final accent = HexColor('#A2BF49');
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _replies.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => ActionChip(
            label: Text(
              _replies[i],
              style: const TextStyle(fontSize: 12, color: Color(0xFF3F5A0B), fontWeight: FontWeight.w500),
            ),
            backgroundColor: accent.withOpacity(0.12),
            side: BorderSide(color: accent.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onPressed: () => widget.onSend(_replies[i]),
          ),
        ),
      ),
    );
  }
}
