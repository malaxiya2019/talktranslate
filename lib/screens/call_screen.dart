import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call.dart';
import '../providers/call_provider.dart';
import '../widgets/common/avatar.dart';
import '../widgets/common/glass_container.dart';
import '../widgets/call/connection_status_card.dart';
import '../widgets/call/call_actions_bar.dart';

import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/translation_card.dart';
import '../l10n/l10n.dart';

/// 通话页面 — Selector 局部绑定，防 rebuild 风暴
class CallScreen extends StatefulWidget {
  const CallScreen({super.key});
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Timer? _timer;
  int _elapsed = 0;
  bool _muted = false;
  bool _speaker = false;

  late final AnimationController _exitCtrl;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitFade;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _exitScale = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInCubic));
    _exitFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _exitCtrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _animateExit() async {
    setState(() => _exiting = true);
    _exitCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 250));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  void _onAction(ActionType type) {
    final cp = context.read<CallProvider>();
    switch (type) {
      case ActionType.minimize:
        cp.enterBackgroundMode();
        if (mounted) Navigator.pop(context);
        break;
      case ActionType.mute:
        setState(() => _muted = !_muted);
        break;
      case ActionType.speaker:
        setState(() => _speaker = !_speaker);
        break;
      case ActionType.hangup:
        _animateExit().then((_) {
          cp.hangup();
          if (mounted) Navigator.pop(context);
        });
        break;
      case ActionType.answer:
        cp.accept();
        break;
      case ActionType.reject:
        cp.reject();
        if (mounted) Navigator.pop(context);
        break;
    }
  }

  // ── 主构建：仅 CallState 变化时触发 ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: _exiting
          ? FadeTransition(
              opacity: _exitFade,
              child: ScaleTransition(
                scale: _exitScale,
                child: _buildCallBody(),
              ),
            )
          : _buildCallBody(),
    );
  }

  /// 通话主体内容（Selector 隔离，仅 CallState 变化时重建）
  Widget _buildCallBody() {
    return Selector<CallProvider, CallState>(
      selector: (_, cp) => cp.callState,
      builder: (context, st, _) {
        if (st == CallState.inCall && _timer == null) _startTimer();
        if (st == CallState.idle) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => Navigator.pop(context),
          );
        }
        return SafeArea(child: _buildSwipeableBody(st));
      },
    );
  }

  // ── 下滑挂断手势 ──

  Widget _buildSwipeableBody(CallState st) {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 800) {
          _onAction(ActionType.hangup);
        }
      },
      child: Stack(
        children: [
          Column(
            children: [
              if (st == CallState.inCall)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              _buildTopBar(st),
              const Divider(color: Colors.white12, height: 1),
              Expanded(child: _buildBody(st)),
              CallActionsBar(
                muted: _muted,
                speakerOn: _speaker,
                ringingMode: st == CallState.ringing,
                onAction: _onAction,
              ),
            ],
          ),
          if (st == CallState.reconnecting)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildReconnectingBanner(),
            ),
        ],
      ),
    );
  }

  // ── 顶部栏（CallState Selector 驱动）──

  Widget _buildTopBar(CallState st) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (st == CallState.inCall)
            Selector<CallProvider, int>(
              selector: (_, cp) => cp.pingMs,
              builder: (_, ms, __) => ConnectionStatusCard(state: st, pingMs: ms),
            ),
          const Spacer(),
          GestureDetector(
            onTap: () => _onAction(ActionType.minimize),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.white70, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── 主体 ──

  Widget _buildBody(CallState st) {
    return st == CallState.connecting ||
            st == CallState.ringing
        ? _buildRingingView(st)
        : _buildInCallView();
  }

  // ── 重连提示横幅 ──

  Widget _buildReconnectingBanner() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.2),
              Colors.orange.withValues(alpha: 0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
              ),
            ),
            SizedBox(width: 8),
            Text(L10n.of(context)!.reconnecting,
              style: TextStyle(fontSize: 13, color: Colors.orangeAccent[200]),
            ),
          ],
        ),
      ),
    );
  }

  // ── 响铃/连接页 ──

  Widget _buildRingingView(CallState st) {
    return Column(
      key: const ValueKey('ringing'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Selector<CallProvider, String>(
          selector: (_, cp) => cp.peerPhone ?? '',
          builder: (_, phone, __) => Avatar(
            name: phone.isNotEmpty ? phone : '?',
            size: 88,
            online: false,
          ),
        ),
        SizedBox(height: 16),
        Selector<CallProvider, String>(
          selector: (_, cp) => cp.peerPhone ?? '',
          builder: (_, phone, __) => Text(
            phone,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          st == CallState.connecting ? L10n.of(context)!.calling : L10n.of(context)!.ringing,
          style: const TextStyle(fontSize: 15, color: Colors.white38),
        ),
      ],
    );
  }

  // ── 通话中：翻译界面（subtitle/mySpeech 各自 Selector）──

  Widget _buildInCallView() {
    return Column(
      key: const ValueKey('inCall'),
      children: [
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🇨🇳 中文',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.swap_horiz, color: Colors.grey[600], size: 18),
            ),
            Text(
              '🇺🇸 English',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
        SizedBox(height: 4),
        Selector<CallProvider, String>(
          selector: (_, cp) => cp.peerPhone ?? '',
          builder: (_, phone, __) => Text(
            phone,
            style: const TextStyle(fontSize: 16, color: Colors.white54),
          ),
        ),
        SizedBox(height: 16),

        // 对方字幕（subtitle 独立 Selector）
        Expanded(
          child: GlassContainer(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Selector<CallProvider, String>(
                  selector: (_, cp) => cp.subtitle,
                  builder: (_, text, __) => MessageBubble(
                    speaker: Speaker.peer,
                    text: text,
                    color: Colors.orangeAccent,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 10),
                Selector<CallProvider, String>(
                  selector: (_, cp) => cp.subtitleTranslated,
                  builder: (_, translated, __) => TranslationCard(
                    original: '',
                    translated: translated,
                    translatedFontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 8),

        // 我的字幕（mySpeech 独立 Selector）
        Expanded(
          child: GlassContainer(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            borderColor: Colors.white.withValues(alpha: 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Selector<CallProvider, String>(
                  selector: (_, cp) => cp.mySpeech,
                  builder: (_, text, __) => MessageBubble(
                    speaker: Speaker.me,
                    text: text,
                    color: Colors.blue[300]!,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Selector<CallProvider, String>(
                  selector: (_, cp) => cp.mySpeechTranslated,
                  builder: (_, translated, __) => TranslationCard(
                    original: '',
                    translated: translated,
                    originalFontSize: 16,
                    translatedFontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}
