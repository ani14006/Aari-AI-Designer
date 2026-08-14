import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Full-screen blocking wait state shown while the app is on a long-running AI step (colour
/// analysis, preview generation, shopping-list generation). Five staggered pulsing dots, an
/// eyebrow label, a rotating italic status message, and a static subcopy line — no app bar, no
/// back button, since there's nothing to navigate to until the step finishes.
///
/// [messages] and [subcopy] default to the colour-analysis step's copy; pass step-specific copy
/// (e.g. "Draping the silk…" for the preview render) for other long-running steps.
class BufferScreen extends StatefulWidget {
  final List<String> messages;
  final String subcopy;

  static const defaultMessages = [
    'Simmering the colour palette…',
    'Cooking up your custom look…',
    'Plating the final design…',
    'Adding the finishing touch…',
  ];

  const BufferScreen({
    super.key,
    this.messages = defaultMessages,
    this.subcopy = 'Cooking up your custom look',
  });

  @override
  State<BufferScreen> createState() => _BufferScreenState();
}

class _BufferScreenState extends State<BufferScreen>
    with SingleTickerProviderStateMixin {
  static const _dotCount = 5;
  static const _dotCycle = Duration(milliseconds: 1200);
  static const _messageCycle = Duration(milliseconds: 1800);
  static const _staggerFraction =
      200 / 1200; // 0.2s stagger within a 1.2s cycle

  late final AnimationController _dotsController;
  late final Timer _messageTimer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(vsync: this, duration: _dotCycle)
      ..repeat();
    _messageTimer = Timer.periodic(_messageCycle, (_) {
      setState(
          () => _messageIndex = (_messageIndex + 1) % widget.messages.length);
    });
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _messageTimer.cancel();
    super.dispose();
  }

  double _dotOpacity(double t, int dotIndex) {
    final local = (t - dotIndex * _staggerFraction) % 1.0;
    return 0.35 + 0.65 * math.sin(math.pi * local).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _dotsController,
              builder: (context, _) {
                final t = _dotsController.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _dotCount; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Opacity(
                        opacity: _dotOpacity(t, i),
                        child: Container(
                          height: 12,
                          width: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            Text(
              'AARI AI DESIGNER',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.76, // 0.16em at 11px
                color: AppColors.antiqueGold,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                widget.messages[_messageIndex],
                key: ValueKey(_messageIndex),
                textAlign: TextAlign.center,
                style: AppTextStyles.accentItalic(22,
                    color: AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subcopy,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
