import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/conversation/conversation_controller.dart';
import '../../theme/app_tokens.dart';
import '../../utils/utils.dart';
import '../../widgets/ui/back_header.dart';

/// Text-based practice conversation with Dorna (backend F4).
class ConversationScreen extends StatefulWidget {
  static const String routeName = '/conversation';

  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ConversationController _c = Get.put(ConversationController());
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final scene = (args is Map && args['scene'] is String)
        ? args['scene'] as String
        : 'small_talk';
    _c.start(scene).then((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _send() {
    final text = _input.text;
    _input.clear();
    _c.send(text).then((_) => _scrollToEnd());
    _scrollToEnd();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Utils.appContext = context;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Talk with Dorna'),
            Expanded(
              child: Obx(() {
                if (_c.isStarting.value && _c.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: _c.messages.length,
                  itemBuilder: (context, i) => _Bubble(msg: _c.messages[i]),
                );
              }),
            ),
            Obx(() => _c.isSending.value
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('Dorna is typing…',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant)),
                  )
                : const SizedBox.shrink()),
            _InputBar(controller: _input, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ConversationMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isUser = msg.role == 'user';
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          decoration: BoxDecoration(
            gradient: isUser ? DornaColors.brandGradient : null,
            color: isUser ? null : cs.surfaceContainerLow,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(DornaRadii.lg),
              topRight: const Radius.circular(DornaRadii.lg),
              bottomLeft: Radius.circular(isUser ? DornaRadii.lg : DornaRadii.sm),
              bottomRight:
                  Radius.circular(isUser ? DornaRadii.sm : DornaRadii.lg),
            ),
          ),
          child: Text(
            msg.text,
            style: tt.bodyLarge?.copyWith(
                color: isUser ? Colors.white : cs.onSurface, height: 1.35),
          ),
        ),
        if (isUser && (msg.correction != null || msg.tip != null))
          Container(
            margin: const EdgeInsets.only(bottom: 6, top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(DornaRadii.md),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.correction != null)
                  _FeedbackLine(
                      icon: Icons.spellcheck,
                      color: cs.primary,
                      text: msg.correction!),
                if (msg.tip != null) ...[
                  if (msg.correction != null) const SizedBox(height: 6),
                  _FeedbackLine(
                      icon: Icons.lightbulb_outline,
                      color: DornaColors.warning,
                      text: msg.tip!),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _FeedbackLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _FeedbackLine(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurface)),
        ),
      ],
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your reply…',
                filled: true,
                fillColor: cs.surfaceContainerLow,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DornaRadii.full),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSend,
              borderRadius: BorderRadius.circular(DornaRadii.full),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: DornaColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
