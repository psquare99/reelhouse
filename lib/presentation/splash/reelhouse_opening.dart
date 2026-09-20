import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';

/// Cinematic opening experience for REELHOUSE.
///
/// Plays a restrained brand reveal (icon + name + subtitle) on a dark canvas
/// before transitioning to the main application flow. Total sequence ~1.5s.
///
/// Uses only built-in Flutter animations — no external dependencies.
class ReelhouseOpening extends StatefulWidget {
  /// Called once when the opening animation sequence completes.
  final VoidCallback onComplete;

  const ReelhouseOpening({super.key, required this.onComplete});

  @override
  State<ReelhouseOpening> createState() => _ReelhouseOpeningState();
}

class _ReelhouseOpeningState extends State<ReelhouseOpening>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Icon: fade + scale in (0–400ms)
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconScale;

  // Title: fade + slide up (200–600ms)
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;

  // Subtitle: fade in (450–750ms)
  late final Animation<double> _subtitleOpacity;

  // Everything: fade out (1050–1400ms)
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // --- Icon entrance (0.0 – 0.286 = 0–400ms) ---
    _iconOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.286, curve: Curves.easeOut),
      ),
    );
    _iconScale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.286, curve: Curves.easeOut),
      ),
    );

    // --- Title entrance (0.143 – 0.429 = 200–600ms) ---
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.143, 0.429, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.143, 0.429, curve: Curves.easeOut),
          ),
        );

    // --- Subtitle entrance (0.321 – 0.536 = 450–750ms) ---
    _subtitleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.321, 0.536, curve: Curves.easeOut),
      ),
    );

    // --- Global fade out (0.750 – 1.0 = 1050–1400ms) ---
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.750, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onComplete();
      }
    });
  }

  bool _animationStarted = false;
  bool _completed = false;
  Timer? _holdTimer;

  void _startAnimation() {
    if (_animationStarted || _completed) return;
    _animationStarted = true;
    // Brief async pause before starting (200ms) for a clean dark frame.
    Future<void>.delayed(const Duration(milliseconds: 200)).then((_) {
      if (mounted && !_completed) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Static branded opening for reduced-motion users — no animation, same
  /// visual identity at full opacity.
  Widget _buildStaticOpening() {
    return ColoredBox(
      color: CinemaColors.darkBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: CinemaColors.darkAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: CinemaColors.darkAccent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.movie_filter_rounded,
                  color: CinemaColors.darkAccent,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'REELHOUSE',
              style: TextStyle(
                color: CinemaColors.darkTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personal Digital Cinema',
              style: TextStyle(
                color: CinemaColors.darkAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool skipAnimations = MediaQuery.of(context).disableAnimations;

    if (skipAnimations) {
      // Reduced-motion: show static branded opening, hold briefly, then complete.
      if (!_completed) {
        _completed = true;
        _holdTimer = Timer(const Duration(milliseconds: 600), () {
          if (mounted) widget.onComplete();
        });
      }
      return _buildStaticOpening();
    }

    // Start the animation on first build (guarded against multiple calls).
    _startAnimation();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _fadeOut.value,
          child: ColoredBox(
            color: CinemaColors.darkBackground,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Icon ---
                  Opacity(
                    opacity: _iconOpacity.value,
                    child: Transform.scale(
                      scale: _iconScale.value,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: CinemaColors.darkAccent.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CinemaColors.darkAccent.withValues(
                              alpha: 0.3,
                            ),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.movie_filter_rounded,
                            color: CinemaColors.darkAccent,
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- Title ---
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleOpacity,
                      child: Text(
                        'REELHOUSE',
                        style: TextStyle(
                          color: CinemaColors.darkTextPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // --- Subtitle ---
                  FadeTransition(
                    opacity: _subtitleOpacity,
                    child: Text(
                      'Personal Digital Cinema',
                      style: TextStyle(
                        color: CinemaColors.darkAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
