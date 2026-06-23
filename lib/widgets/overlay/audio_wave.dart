import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 音频波形动画 — 通话中自动跳动，模拟实时音频感
///
/// 用法：
/// ```dart
/// AudioWave(active: state == CallState.inCall)
/// ```
class AudioWave extends StatefulWidget {
  final bool active;
  final Color barColor;
  final int barCount;

  const AudioWave({
    super.key,
    this.active = false,
    this.barColor = Colors.greenAccent,
    this.barCount = 5,
  });

  @override
  State<AudioWave> createState() => _AudioWaveState();
}

class _AudioWaveState extends State<AudioWave> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  Timer? _timer;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.barCount,
      (_) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + _random.nextInt(300)),
      ),
    );
    _animations = _controllers
        .map(
          (c) => Tween<double>(
            begin: 0.15,
            end: 1.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();
    if (widget.active) _startWave();
  }

  @override
  void didUpdateWidget(AudioWave old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _startWave();
    if (!widget.active && old.active) _stopWave();
  }

  void _startWave() {
    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      for (final c in _controllers) {
        if (c.isAnimating) continue;
        c.forward().then((_) => c.reverse());
      }
    });
    // 立即触发一波
    for (final c in _controllers) {
      Future.delayed(Duration(milliseconds: _random.nextInt(200)), () {
        if (mounted) c.forward().then((_) => c.reverse());
      });
    }
  }

  void _stopWave() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.reset();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.barCount, (i) {
          if (!widget.active) {
            return Container(
              width: 3,
              height: 4,
              decoration: BoxDecoration(
                color: widget.barColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) => Container(
              width: 3,
              height: 4 + 14 * _animations[i].value,
              decoration: BoxDecoration(
                color: widget.barColor.withValues(
                  alpha: 0.4 + 0.6 * _animations[i].value,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
