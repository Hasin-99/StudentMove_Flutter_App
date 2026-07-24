import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/chat_repository.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<({String text, bool agent, DateTime time})> _aiMessages = [];
  late final TabController _tabs;
  Timer? _poller;
  bool _aiThinking = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    for (final h in AiAssistantService.history) {
      _aiMessages.add((
        text: h.text,
        agent: h.role == 'assistant',
        time: DateTime.now(),
      ));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshChat();
      _poller = Timer.periodic(const Duration(seconds: 7), (_) {
        if (_tabs.index == 1) _refreshChat();
      });
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    _tabs.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _messageController.text.trim();
    if (t.isEmpty) return;
    _messageController.clear();

    if (_tabs.index == 0) {
      setState(() {
        _aiMessages.add((text: t, agent: false, time: DateTime.now()));
        _aiThinking = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 420));
      final answer = AiAssistantService.reply(t);
      if (!mounted) return;
      setState(() {
        _aiThinking = false;
        _aiMessages.add((text: answer, agent: true, time: DateTime.now()));
      });
      return;
    }

    final email = context.read<AuthProvider>().userEmail;
    if (email == null || email.isEmpty) return;
    await context.read<ChatRepository>().sendMessage(email: email, text: t);
  }

  Future<void> _refreshChat() async {
    if (!mounted) return;
    final email = context.read<AuthProvider>().userEmail;
    if (email == null || email.isEmpty) return;
    await context.read<ChatRepository>().refresh(email);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ChatRepository>();
    final messages = repo.messages;
    final hPad = AppLayout.pageHPadFor(context);
    final maxWidth = AppLayout.contentMaxWidthFor(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                Padding(
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
                        backgroundColor:
                            AppColors.brandLight.withValues(alpha: 0.18),
                        child: Icon(
                          _tabs.index == 0
                              ? Icons.smart_toy_rounded
                              : Icons.support_agent_rounded,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'StudentMove Chat',
                              style: GoogleFonts.syne(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              'Dhaka · AI + Support',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_tabs.index == 0)
                        _RoundActionButton(
                          icon: Icons.delete_outline_rounded,
                          onTap: () {
                            AiAssistantService.clear();
                            setState(() => _aiMessages.clear());
                          },
                        )
                      else
                        _RoundActionButton(
                          icon: Icons.refresh_rounded,
                          onTap: _refreshChat,
                        ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  onTap: (_) => setState(() {}),
                  labelColor: AppColors.brand,
                  unselectedLabelColor: AppColors.muted,
                  indicatorColor: AppColors.accent,
                  labelStyle:
                      GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'AI Assistant'),
                    Tab(text: 'Support'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _aiMessages.isEmpty
                          ? ListView(
                              padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 10),
                              children: const [
                                _SampleBubble(
                                  text:
                                      'Ask about routes, fares, schedules, or student passes.',
                                  agent: true,
                                ),
                                _SampleBubble(
                                  text: 'How much is the monthly pass?',
                                  agent: false,
                                ),
                              ],
                            )
                          : ListView.builder(
                              reverse: true,
                              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 10),
                              itemCount:
                                  _aiMessages.length + (_aiThinking ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (_aiThinking && i == 0) {
                                  return const _Bubble(
                                    text: 'Thinking…',
                                    agent: true,
                                    time: null,
                                  );
                                }
                                final idx = _aiThinking
                                    ? _aiMessages.length - i
                                    : _aiMessages.length - 1 - i;
                                final msg = _aiMessages[idx];
                                return _Bubble(
                                  text: msg.text,
                                  agent: msg.agent,
                                  time: msg.time,
                                );
                              },
                            ),
                      messages.isEmpty && repo.loading
                          ? const Center(child: CircularProgressIndicator())
                          : messages.isEmpty
                              ? ListView(
                                  padding:
                                      EdgeInsets.fromLTRB(hPad, 24, hPad, 10),
                                  children: const [
                                    _SampleBubble(
                                      text: 'How can I help with your ride?',
                                      agent: true,
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  reverse: true,
                                  padding:
                                      EdgeInsets.fromLTRB(hPad, 12, hPad, 10),
                                  itemCount: messages.length,
                                  itemBuilder: (context, i) {
                                    final msg =
                                        messages[messages.length - 1 - i];
                                    return _Bubble(
                                      text: msg.text,
                                      agent: msg.fromAdmin,
                                      time: msg.createdAt,
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
                if (repo.lastError != null && _tabs.index == 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: Text(
                      repo.lastError!,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    8,
                    hPad,
                    8 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppTheme.elev1,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _tabs.index == 0
                              ? Icons.auto_awesome_rounded
                              : Icons.attach_file_rounded,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            style: GoogleFonts.ibmPlexSans(fontSize: 15),
                            decoration: InputDecoration(
                              hintText: _tabs.index == 0
                                  ? 'Ask the AI assistant…'
                                  : 'Message support…',
                              hintStyle: GoogleFonts.ibmPlexSans(
                                color: AppColors.muted,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: _send,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            minimumSize: const Size(42, 42),
                            padding: EdgeInsets.zero,
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(Icons.send_rounded, size: 20),
                        ),
                      ],
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
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
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
  final DateTime? time;

  @override
  Widget build(BuildContext context) {
    if (!agent) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
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
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (time != null) ...[
                const SizedBox(height: 6),
                Text(
                  TimeOfDay.fromDateTime(time!).format(context),
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
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
            child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.72,
              ),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      TimeOfDay.fromDateTime(time!).format(context),
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
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
    return _Bubble(text: text, agent: agent, time: null);
  }
}
