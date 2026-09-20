import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/cinema_colors.dart';

// --- Opening-specific palette (not exported — scoped to this file) ---
const Color _accent = Color(0xFFC75A28);
const Color _accentHighlight = Color(0xFFE97A3A);
const Color _titleColor = Color(0xFFF5F1EA);

/// Cinematic opening experience for REELHOUSE.
///
/// Plays a restrained brand reveal (clapperboard icon + MATINEE + subtitle)
/// on a dark canvas with a spotlight gradient and floor reflection.
/// Total sequence ~1.8 s (200 ms dark frame + 1600 ms animation).
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

  // Global fade-out (1350–1600 ms = Interval 0.84375–1.0)
  late final Animation<double> _fadeOut;

  bool _animationStarted = false;
  bool _completed = false;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.84375, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onComplete();
      }
    });
  }

  void _startAnimation() {
    if (_animationStarted || _completed) return;
    _animationStarted = true;
    // Brief async pause before starting (200 ms) for a clean dark frame.
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

  // ------------------------------------------------------------------
  // Shared content — used by both animated and static (reduced-motion)
  // paths so the visual identity is identical.
  // ------------------------------------------------------------------

  Widget _buildContent({
    required double spotlightOpacity,
    required double iconOpacity,
    required double iconScale,
    required double titleOpacity,
    required double titleSlideY,
    required double subtitleOpacity,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // --- Dark background ---
        const ColoredBox(color: CinemaColors.darkBackground),

        // --- Spotlight gradient (fades in 0–300 ms) ---
        Opacity(
          opacity: spotlightOpacity,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.35),
                radius: 0.75,
                colors: [
                  Color(0x18C75A28),
                  Color(0x08C75A28),
                  Colors.transparent,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // --- Main content ---
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Clapperboard icon (rounded-square) ---
              Opacity(
                opacity: iconOpacity,
                child: Transform.scale(
                  scale: iconScale,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.movie_filter_rounded,
                        color: _accentHighlight,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- Title: MATINEE ---
              Opacity(
                opacity: titleOpacity,
                child: Transform.translate(
                  offset: Offset(0, titleSlideY),
                  child: Text(
                    'MATINEE',
                    style: TextStyle(
                      color: _titleColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6.0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // --- Subtitle ---
              Opacity(
                opacity: subtitleOpacity,
                child: Text(
                  'Personal Digital Cinema',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- Subtle floor reflection (gradient mask near bottom) ---
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 90,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_accent.withValues(alpha: 0.04), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Static branded opening — reduced-motion (disableAnimations == true).
  // Shows the same visual at full opacity for ~600 ms, then completes.
  // ------------------------------------------------------------------

  Widget _buildStaticOpening() {
    return _buildContent(
      spotlightOpacity: 1.0,
      iconOpacity: 1.0,
      iconScale: 1.0,
      titleOpacity: 1.0,
      titleSlideY: 0,
      subtitleOpacity: 1.0,
    );
  }

  // ------------------------------------------------------------------
  // Animated opening — normal motion path.
  // ------------------------------------------------------------------

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
        final double t = _controller.value;

        // Spotlight fade-in: 0–300 ms (Interval 0.0–0.1875)
        final double spotlightOpacity = Curves.easeOut.transform(
          t.clamp(0.0, 0.1875),
        );

        // Icon: opacity 0→1, scale 0.92→1.0 (Interval 0.0–0.25)
        final double iconT = Curves.easeOutCubic.transform(t.clamp(0.0, 0.25));

        // Title: fade + slide up 6 px (Interval 0.156–0.375)
        // Clamp to interval, normalise to 0–1, then ease.
        final double titleRaw = t.clamp(0.156, 0.375);
        final double titleNorm = (titleRaw - 0.156) / (0.375 - 0.156);
        final double titleEased = Curves.easeOut.transform(titleNorm);

        // Subtitle: soft fade (Interval 0.3125–0.5)
        final double subtitleRaw = t.clamp(0.3125, 0.5);
        final double subtitleNorm = (subtitleRaw - 0.3125) / (0.5 - 0.3125);
        final double subtitleEased = Curves.easeOut.transform(subtitleNorm);

        return Opacity(
          opacity: _fadeOut.value,
          child: _buildContent(
            spotlightOpacity: spotlightOpacity,
            iconOpacity: iconT,
            iconScale: 0.92 + 0.08 * iconT,
            titleOpacity: titleEased,
            titleSlideY: 6 * (1 - titleEased),
            subtitleOpacity: subtitleEased,
          ),
        );
      },
    );
  }
}
