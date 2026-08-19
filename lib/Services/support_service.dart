import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';

/// One message in a support thread.
class SupportMessage {
  final String id;
  final String senderType; // USER | ADMIN
  final String message;
  final DateTime? createdAt;

  SupportMessage({
    required this.id,
    required this.senderType,
    required this.message,
    this.createdAt,
  });

  bool get isMine => senderType.toUpperCase() == 'USER';

  factory SupportMessage.fromJson(Map<String, dynamic> j) => SupportMessage(
        id: (j['_id'] ?? '').toString(),
        senderType: (j['senderType'] ?? 'ADMIN').toString(),
        message: (j['message'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()),
      );
}

/// A support ticket as shown in the list.
class SupportTicket {
  final String id;
  final String ticketId; // human "TKT..." code
  final String subject;
  final String category;
  final String status; // OPEN | IN_PROGRESS | WAITING_FOR_USER | RESOLVED | CLOSED
  final DateTime? createdAt;
  final DateTime? lastMessageAt;

  SupportTicket({
    required this.id,
    required this.ticketId,
    required this.subject,
    required this.category,
    required this.status,
    this.createdAt,
    this.lastMessageAt,
  });

  bool get isClosed {
    final s = status.toUpperCase();
    return s == 'CLOSED' || s == 'RESOLVED';
  }

  factory SupportTicket.fromJson(Map<String, dynamic> j) => SupportTicket(
        id: (j['_id'] ?? '').toString(),
        ticketId: (j['ticketId'] ?? '').toString(),
        subject: (j['subject'] ?? 'Support request').toString(),
        category: (j['category'] ?? '').toString(),
        status: (j['status'] ?? 'OPEN').toString(),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()),
        lastMessageAt:
            DateTime.tryParse((j['lastMessageAt'] ?? '').toString()),
      );
}

/// Support tickets: list, read a thread, reply, close.
///
/// The backend has always exposed these; the app only ever POSTed new tickets,
/// so a customer could raise a complaint and never see the response.
class Faq {
  final String id;
  final String question;
  final String answer;

  /// Needed so the Help screen can group an ungrouped fetch back into
  /// categories — otherwise an admin-created category could never surface.
  final String category;

  Faq({
    required this.id,
    required this.question,
    required this.answer,
    this.category = '',
  });

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        question: (json['question'] ?? '').toString(),
        answer: (json['answer'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
      );
}

class SupportService {
  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Prefs.getString('token')}',
      };

  /// These routes answer `{success, data}` (not the {code,message,data} envelope).
  static bool _ok(http.Response r, dynamic body) =>
      (r.statusCode == 200 || r.statusCode == 201) &&
      (body is Map && body['success'] == true);

  /// FAQs for one issue category. These lived hardcoded in the app, so support
  /// answers could only be corrected by shipping a release.
  /// Pass an empty category to fetch every FAQ — the Help screen builds its
  /// category grid from what comes back, so a category the admin creates shows
  /// up without an app release.
  static Future<List<Faq>> getFaqs(String category) async {
    final url = category.isEmpty
        ? ApiUrls.supportAllFaqsUrl
        : ApiUrls.supportFaqsUrl(category);
    final res = await http
        .get(Uri.parse(url), headers: _headers())
        .timeout(const Duration(seconds: 20));
    final body = jsonDecode(res.body);
    if (!_ok(res, body)) {
      throw Exception(
          (body is Map ? body['message'] : null) ?? 'Failed to load FAQs');
    }
    final list = (body['data'] as List?) ?? [];
    return list
        .map((e) => Faq.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Record whether an answer helped. Best-effort: the customer already got
  /// their answer, so a failed vote must not interrupt them.
  static Future<void> rateFaq(String faqId, bool helpful) async {
    if (faqId.isEmpty) return;
    await http
        .post(
          Uri.parse(ApiUrls.supportFaqFeedbackUrl(faqId)),
          headers: _headers(),
          body: jsonEncode({'helpful': helpful}),
        )
        .timeout(const Duration(seconds: 10));
  }

  static Future<List<SupportTicket>> getTickets() async {
    final res = await http
        .get(Uri.parse('${ApiUrls.supportTicketsUrl}?page=1&limit=50'),
            headers: _headers())
        .timeout(const Duration(seconds: 20));
    final body = jsonDecode(res.body);
    if (!_ok(res, body)) {
      throw Exception(
          (body is Map ? body['message'] : null) ?? 'Failed to load tickets');
    }
    final list = (body['data']?['tickets'] as List?) ?? [];
    return list
        .map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Returns the ticket plus its CUSTOMER-channel messages.
  static Future<(SupportTicket, List<SupportMessage>)> getThread(
      String ticketId) async {
    final res = await http
        .get(Uri.parse(ApiUrls.supportTicketDetailUrl(ticketId)),
            headers: _headers())
        .timeout(const Duration(seconds: 20));
    final body = jsonDecode(res.body);
    if (!_ok(res, body)) {
      throw Exception(
          (body is Map ? body['message'] : null) ?? 'Failed to load ticket');
    }
    final data = body['data'] ?? {};
    final ticket =
        SupportTicket.fromJson(Map<String, dynamic>.from(data['ticket'] ?? {}));
    final msgs = ((data['messages'] as List?) ?? [])
        .map((e) => SupportMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (ticket, msgs);
  }

  /// Reply on an open ticket. Returns (ok, message).
  static Future<(bool, String)> reply(String ticketId, String message) async {
    try {
      final res = await http
          .post(Uri.parse(ApiUrls.supportTicketReplyUrl(ticketId)),
              headers: _headers(),
              body: jsonEncode({'message': message, 'messageType': 'TEXT'}))
          .timeout(const Duration(seconds: 20));
      final body = jsonDecode(res.body);
      return (
        _ok(res, body),
        ((body is Map ? body['message'] : null) ?? '').toString()
      );
    } catch (e) {
      return (false, 'Could not send: $e');
    }
  }

  static Future<bool> close(String ticketId) async {
    try {
      final res = await http
          .post(Uri.parse(ApiUrls.supportTicketCloseUrl(ticketId)),
              headers: _headers(), body: jsonEncode({}))
          .timeout(const Duration(seconds: 20));
      return _ok(res, jsonDecode(res.body));
    } catch (_) {
      return false;
    }
  }
}
