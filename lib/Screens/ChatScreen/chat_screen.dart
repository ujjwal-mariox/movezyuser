import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/Screens/ChatScreen/chat_service.dart';
import 'package:hexcolor/hexcolor.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String driverName;

  const ChatScreen({
    super.key,
    required this.bookingId,
    this.driverName = 'Driver',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatService _chat;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _chat = ChatService(bookingId: widget.bookingId);
    _chat.messages.addListener(_onMessages);
    _chat.loadHistory().then((_) => _scrollToBottom());
    _chat.connect();
  }

  void _onMessages() {
    if (mounted) setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _chat.sendMessage(text);
    _controller.clear();
  }

  Future<void> _pickAndSendImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    await _chat.sendImage(File(picked.path));
  }

  @override
  void dispose() {
    _chat.messages.removeListener(_onMessages);
    _chat.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ));

    final messages = _chat.messages.value;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          commonAppBar(
            height: 100,
            context: context,
            child: Container(
              padding: const EdgeInsets.only(top: 47),
              child: Row(
                children: [
                  const SizedBox(width: 5),
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
                  Expanded(
                    child: Text(
                      widget.driverName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _chat.isConnected,
                    builder: (context, connected, _) => Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.circle,
                        size: 12,
                        color: connected ? Colors.greenAccent : Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet. Say hi 👋',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      if (m.isImage && (m.imageUrl ?? '').isNotEmpty) {
                        return _ImageBubble(url: m.imageUrl!, isMe: m.isMe);
                      }
                      return _ChatBubble(
                        text: m.message,
                        isMe: m.isMe,
                        time: DateFormat('HH:mm').format(m.createdAt.toLocal()),
                      );
                    },
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.3)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          const SizedBox(width: 5),
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: "Send a message...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: _pickAndSendImage,
          ),
          InkWell(
            onTap: _send,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HexColor("#A2BF49"),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  const _ChatBubble({
    required this.text,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: isMe ? HexColor("#A2BF49") : const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 15, color: isMe ? Colors.white : Colors.black),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              time,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final String url;
  final bool isMe;

  const _ImageBubble({required this.url, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 160,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              width: 160,
              height: 160,
              color: const Color(0xFFF6F6F6),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}
