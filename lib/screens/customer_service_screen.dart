import 'package:flutter/material.dart' hide Text;

import '../widgets/auth_style.dart';
import '../widgets/localized_text.dart';

const _bubbleGrey = Color(0xFFF1F3F2);

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;
}

class CustomerServiceScreen extends StatefulWidget {
  const CustomerServiceScreen({super.key});

  @override
  State<CustomerServiceScreen> createState() => _CustomerServiceScreenState();
}

class _CustomerServiceScreenState extends State<CustomerServiceScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[
    _ChatMessage(
      text: tr('Hi! Welcome to SeatNix support. How can we help you today?'),
      fromUser: false,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
    });
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _bubble(_ChatMessage message) {
    final alignment = message.fromUser
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.fromUser ? accentColor(context) : _bubbleGrey,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(16),
            topEnd: const Radius.circular(16),
            bottomStart: Radius.circular(message.fromUser ? 16 : 4),
            bottomEnd: Radius.circular(message.fromUser ? 4 : 16),
          ),
          border: Border.fromBorderSide(appCardBorder(context)),
          boxShadow: appCardShadow(context),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.fromUser ? Colors.white : primaryText(context),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground(context),
      appBar: AppBar(
        backgroundColor: screenBackground(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            directionalBackIcon(context),
            textDirection: TextDirection.ltr,
            color: primaryText(context),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Customer Service',
          style: TextStyle(
            color: primaryText(context),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                itemCount: _messages.length,
                itemBuilder: (_, index) => _bubble(_messages[index]),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: dividerColor(context))),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: TextStyle(
                        color: primaryText(context),
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: tr('Type your message'),
                        hintStyle: TextStyle(color: mutedText(context)),
                        filled: true,
                        fillColor: _bubbleGrey,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: accentColor(context),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sendMessage,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
