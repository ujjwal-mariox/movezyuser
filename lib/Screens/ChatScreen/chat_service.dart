import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:movezy_user_app/ApiUrls/api_urls.dart';
import 'package:movezy_user_app/Utils/PrefsManager/prefs_manager.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatMessage {
  final String? id;
  final String bookingId;
  final String senderId;
  final String senderType;
  final String messageType;
  final String message;
  final String? imageUrl;
  final DateTime createdAt;

  ChatMessage({
    this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    required this.message,
    this.imageUrl,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id']?.toString(),
      bookingId: json['bookingId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderType: json['senderType']?.toString() ?? 'USER',
      messageType: json['messageType']?.toString() ?? 'TEXT',
      message: json['message']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  // In the customer app, "me" is the USER side.
  bool get isMe => senderType == 'USER';
  bool get isImage => messageType == 'IMAGE';
}

class ChatService {
  IO.Socket? _socket;
  final String bookingId;
  final ValueNotifier<List<ChatMessage>> messages = ValueNotifier([]);
  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  ChatService({required this.bookingId});

  String get _token => Prefs.getString('token');

  /// Connect to socket and join booking room
  void connect() {
    _socket = IO.io(
      ApiUrls.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': _token})
          // forceNew is required: socket_io_client caches connections per URL.
          // After dispose() the cached, destroyed socket is what the NEXT
          // IO.io() returns — autoConnect doesn't re-fire, so onConnect never
          // runs and chat:join is never sent. The second chat opened in a
          // session would silently never connect (and a re-login would reuse
          // the previous user's token). Same fix as the driver app.
          .enableForceNew()
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('Chat socket connected');
      isConnected.value = true;
      _joinRoom();
    });

    _socket!.onDisconnect((_) {
      debugPrint('Chat socket disconnected');
      isConnected.value = false;
    });

    _socket!.onConnectError((data) {
      debugPrint('Chat socket connection error: $data');
      isConnected.value = false;
    });

    // Listen for incoming messages
    _socket!.on('chat:message', (data) {
      final msg = ChatMessage.fromJson(data as Map<String, dynamic>);
      final current = List<ChatMessage>.from(messages.value);
      if (msg.id != null && current.any((m) => m.id == msg.id)) return;
      current.add(msg);
      messages.value = current;
    });

    _socket!.on('chat:error', (data) {
      debugPrint('Chat error: $data');
    });

    // Socket.io does not replay 'connect' for listeners added after the socket
    // is already connected, so join explicitly in that case.
    if (_socket!.connected) {
      isConnected.value = true;
      _joinRoom();
    }
  }

  /// Join the booking room and mark existing messages as read.
  void _joinRoom() {
    _socket!.emit('chat:join', {'bookingId': bookingId});
    _socket!.emit('chat:read', {'bookingId': bookingId});
  }

  /// Send a text message
  void sendMessage(String text) {
    if (text.trim().isEmpty || _socket == null) return;

    _socket!.emit('chat:message', {
      'bookingId': bookingId,
      'message': text.trim(),
      'messageType': 'TEXT',
    });
  }

  /// Send an image message (upload first, then emit via socket)
  Future<void> sendImage(File imageFile) async {
    try {
      final imageUrl = await _uploadImage(imageFile);
      if (imageUrl == null) return;

      _socket!.emit('chat:message', {
        'bookingId': bookingId,
        'message': '',
        'messageType': 'IMAGE',
        'imageUrl': imageUrl,
      });
    } catch (e) {
      debugPrint('Error sending image: $e');
    }
  }

  /// Upload image via REST API, returns the URL
  Future<String?> _uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiUrls.chatUploadImageUrl(bookingId)),
      );

      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final url = body['data']?['imageUrl'];
        // Backend may return a String or a List of URLs.
        if (url is List && url.isNotEmpty) return url.first.toString();
        return url?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  /// Load chat history from REST API
  Future<void> loadHistory() async {
    try {
      final response = await http.get(
        Uri.parse(ApiUrls.chatHistoryUrl(bookingId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['data']?['messages'] as List? ?? [];
        messages.value = list
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  /// Disconnect and clean up
  void dispose() {
    _socket?.emit('chat:leave', {'bookingId': bookingId});
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    messages.dispose();
    isConnected.dispose();
  }
}
