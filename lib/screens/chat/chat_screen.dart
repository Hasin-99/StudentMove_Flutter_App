import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion_specs.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshChat();
      _poller = Timer.periodic(const Duration(seconds: 7), (_) => _refreshChat());
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _messageController.text.trim();
    if (t.isEmpty) return;
    final email = context.read<AuthProvider>().userEmail;
    if (email == null || email.isEmpty) return;

    _messageController.clear();
    try {
      await context.read<ChatRepository>().sendMessage(email: email, text: t);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Chat send failed: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send message. Please try again.')),
      );
    }
  }

  Future<void> _refreshChat() async {
    if (!mounted) return;
    final email = context.read<AuthProvider>().userEmail;
    if (email == null || email.isEmpty) return;
    try {
      await context.read<ChatRepository>().refresh(email);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Chat refresh failed: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not refresh chat right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ChatRepository>();
    final messages = repo.messages;
    final hPad = AppLayout.pageHPadFor(context);
    final maxWidth = AppLayout.contentMaxWidthFor(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
          children: [
            AnimatedSection(
              order: 0,
              child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 4),
              child: Row(
                children: [
                  _RoundActionButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                        return;
                      }
                      widget.onBack?.call();
                    },
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.brandLight.withValues(alpha: 0.18),
                    child: const Icon(Icons.remove_red_eye_rounded, color: AppColors.brand),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat Support',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18 * 0.95,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'Uttara, Dhaka',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RoundActionButton(icon: Icons.more_vert_rounded, onTap: _refreshChat),
                ],
              ),
              ),
            ),
            Expanded(
              child: messages.isEmpty && repo.loading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? ListView(
                          padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 10),
                          children: const [
                            _SampleBubble(
                              text: 'How can I book my car?',
                              agent: false,
                            ),
                            _SampleBubble(
                              text: 'How Can I help You? Sir!',
                              agent: true,
                            ),
                            _SampleBubble(text: 'Hi!', agent: false),
                            _SampleBubble(text: 'Hi!', agent: true),
                          ],
                        )
                  : ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 10),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final msg = messages[messages.length - 1 - i];
                        return _Bubble(
                          text: msg.text,
                          agent: msg.fromAdmin,
                          time: msg.createdAt,
                        );
                      },
                    ),
            ),
            if (repo.lastError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(
                  repo.lastError!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            AnimatedSection(
              order: 1,
              child: Padding(
              padding: EdgeInsets.fromLTRB(
                hPad,
                8,
                hPad,
                8 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file_rounded, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: GoogleFonts.plusJakartaSans(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.muted),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: _send,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        minimumSize: const Size(42, 42),
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                        elevation: 2,
                      ),
                      child: const Icon(Icons.send_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: AppColors.brandLight.withValues(alpha: 0.16),
        highlightColor: AppColors.brandLight.withValues(alpha: 0.1),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.ink, size: 20),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.agent, required this.time});
  final String text;
  final bool agent;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    if (!agent) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          decoration: const BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                TimeOfDay.fromDateTime(time).format(context),
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.brand,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.72),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.45,
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    TimeOfDay.fromDateTime(time).format(context),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
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

class _SampleBubble extends StatelessWidget {
  const _SampleBubble({required this.text, required this.agent});

  final String text;
  final bool agent;

  @override
  Widget build(BuildContext context) {
    if (!agent) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.brand,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
