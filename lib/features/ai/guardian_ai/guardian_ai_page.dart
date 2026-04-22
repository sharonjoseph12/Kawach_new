import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:kawach/core/theme/app_colors.dart';
import 'package:kawach/features/ai/guardian_ai/guardian_chat_service.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_bloc.dart';
import 'package:kawach/features/sos/presentation/bloc/sos_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawach/app/di/injection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';

class GuardianAIPage extends StatefulWidget {
  const GuardianAIPage({super.key});

  @override
  State<GuardianAIPage> createState() => _GuardianAIPageState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isStreaming;
  _ChatMessage({required this.text, required this.isUser, this.isStreaming = false});
}

class _GuardianAIPageState extends State<GuardianAIPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = getIt<GuardianChatService>();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _quickPrompts = [
    'I feel unsafe right now',
    'Someone is following me',
    'I need help immediately',
    'Start Safe Walk',
    'What should I do?',
  ];

  @override
  void initState() {
    super.initState();
    _addBotMessage("Hello! I'm your Kawach Guardian AI. I'm here 24/7 to help you stay safe. How can I assist you right now?");
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, {bool isStreaming = false}) {
    setState(() {
      if (isStreaming && _messages.isNotEmpty && !_messages.last.isUser) {
        _messages[_messages.length - 1] = _ChatMessage(text: text, isUser: false, isStreaming: true);
      } else {
        _messages.add(_ChatMessage(text: text, isUser: false, isStreaming: isStreaming));
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    Map<String, dynamic>? contextData;
    try {
       final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
       final battery = await Battery().batteryLevel;
       // Mocked community incident count for God-Mode 2.0 MVP integration
       contextData = {
         'lat': pos.latitude,
         'lng': pos.longitude,
         'battery': battery,
         'time': DateTime.now().toIso8601String(),
         'incidents': 2,
       };
    } catch (_) {}

    bool firstChunk = true;
    await for (final response in _chatService.sendMessage(text, spatialContext: contextData)) {
      if (!mounted) break;
      if (firstChunk) {
        firstChunk = false;
        setState(() => _isTyping = false);
      }
      _addBotMessage(response.text, isStreaming: response.isStreaming);

      // Handle AI-detected actions
      if (!response.isStreaming && response.action != GuardianAction.none) {
        _handleAction(response.action);
      }
    }
    if (mounted) setState(() => _isTyping = false);
  }

  void _handleAction(GuardianAction action) {
    switch (action) {
      case GuardianAction.triggerSos:
        _showActionCard(
          'Trigger SOS?',
          'Guardian AI detected an emergency. Trigger SOS now?',
          AppColors.danger,
          Icons.sos,
          () => context.read<SosBloc>().add(const SosTriggerPressed('guardian_ai')),
        );
        break;
      case GuardianAction.startSafeWalk:
        _showActionCard(
          'Start Safe Walk?',
          'Start monitoring your route with a countdown timer.',
          AppColors.safe,
          Icons.directions_walk,
          () => context.push('/safe-walk'),
        );
        break;
      case GuardianAction.shareLocation:
        _showActionCard(
          'Share Location?',
          'Share your live location with your guardians.',
          AppColors.primary,
          Icons.location_on,
          () {},
        );
        break;
      default:
        break;
    }
  }

  void _showActionCard(String title, String body, Color color, IconData icon, VoidCallback onConfirm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Not now'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () { Navigator.pop(ctx); onConfirm(); },
                  child: const Text('Confirm'),
                )),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guardian AI', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Online • Here for you', style: TextStyle(color: AppColors.safe, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick prompts
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) => ActionChip(
                label: Text(_quickPrompts[i], style: const TextStyle(fontSize: 12)),
                backgroundColor: AppColors.surface,
                labelStyle: const TextStyle(color: AppColors.textPrimary),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                onPressed: () => _sendMessage(_quickPrompts[i]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length) return _TypingIndicator();
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Message Guardian AI...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                message.text.isEmpty ? '...' : message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0), SizedBox(width: 4),
                _Dot(delay: 200), SizedBox(width: 4),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle)),
      ),
    );
  }
}
