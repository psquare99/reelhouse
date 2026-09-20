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
/// on a dark canvas with soft ambient glow and a barely-visible floor light.
/// Total sequence ~1.65 s.
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

  // Global fade-out (1400–1650 ms = Interval 0.8485–1.0)
  late final Animation<double> _fadeOut;

  bool _animationStarted = false;
  bool _completed = false;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1650),
    );

    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8485, 1.0, curve: Curves.easeIn),
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
    _controller.forward();
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
    required double glowOpacity,
    required double iconOpacity,
    required double iconScale,
    required double titleOpacity,
    required double titleSlideY,
    required double subtitleOpacity,
    required double floorGlowOpacity,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // --- Dark background ---
        const ColoredBox(color: CinemaColors.darkBackground),

        // --- Ambient warm glow (soft, wide, centred on composition) ---
        Opacity(
          opacity: glowOpacity,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.05),
                radius: 0.65,
                colors: [
                  Color(0x10C75A28),
                  Color(0x06C75A28),
                  Colors.transparent,
                ],
                stops: [0.0, 0.5, 1.0],
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
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.movie_filter_rounded,
                        color: _accentHighlight,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // --- Title: MATINEE ---
              Opacity(
                opacity: titleOpacity,
                child: Transform.translate(
                  offset: Offset(0, titleSlideY),
                  child: Text(
                    'MATINEE',
                    style: TextStyle(
                      color: _titleColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6.0,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // --- Subtitle ---
              Opacity(
                opacity: subtitleOpacity,
                child: Text(
                  'Personal Digital Cinema',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- Floor glow (extremely subtle warm light near bottom) ---
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 80,
          child: Opacity(
            opacity: floorGlowOpacity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_accent.withValues(alpha: 0.03), Colors.transparent],
                ),
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
      glowOpacity: 1.0,
      iconOpacity: 1.0,
      iconScale: 1.0,
      titleOpacity: 1.0,
      titleSlideY: 0,
      subtitleOpacity: 1.0,
      floorGlowOpacity: 1.0,
    );
  }

  // ------------------------------------------------------------------
  // Animated opening — normal motion path.
  //
  // Timeline (1650 ms total, no initial dark-frame delay):
  //   0–250 ms    ambient glow emerges
  //   200–550 ms  icon fades + scales
  //   450–800 ms  title fades + slides up
  //   650–950 ms  subtitle fades
  //   800–1200 ms floor glow appears
  //   1200–1400 ms quiet hold
  //   1400–1650 ms crossfade out
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

        // Ambient glow: 0–250 ms → Interval(0.0, 0.1515)
        final double glowOpacity = Curves.easeOut.transform(
          t.clamp(0.0, 0.1515),
        );

        // Icon: 200–550 ms → Interval(0.1212, 0.3333)
        final double iconRaw = t.clamp(0.1212, 0.3333);
        final double iconNorm = (iconRaw - 0.1212) / (0.3333 - 0.1212);
        final double iconEased = Curves.easeOutCubic.transform(iconNorm);

        // Title: 450–800 ms → Interval(0.2727, 0.4848)
        final double titleRaw = t.clamp(0.2727, 0.4848);
        final double titleNorm = (titleRaw - 0.2727) / (0.4848 - 0.2727);
        final double titleEased = Curves.easeOut.transform(titleNorm);

        // Subtitle: 650–950 ms → Interval(0.3939, 0.5758)
        final double subtitleRaw = t.clamp(0.3939, 0.5758);
        final double subtitleNorm = (subtitleRaw - 0.3939) / (0.5758 - 0.3939);
        final double subtitleEased = Curves.easeOut.transform(subtitleNorm);

        // Floor glow: 800–1200 ms → Interval(0.4848, 0.7273)
        final double floorRaw = t.clamp(0.4848, 0.7273);
        final double floorNorm = (floorRaw - 0.4848) / (0.7273 - 0.4848);
        final double floorEased = Curves.easeInOut.transform(floorNorm);

        return Opacity(
          opacity: _fadeOut.value.clamp(0.0, 1.0),
          child: _buildContent(
            glowOpacity: glowOpacity,
            iconOpacity: iconEased,
            iconScale: 0.96 + 0.04 * iconEased,
            titleOpacity: titleEased,
            titleSlideY: 5 * (1 - titleEased),
            subtitleOpacity: subtitleEased,
            floorGlowOpacity: floorEased,
          ),
        );
      },
    );
  }
}
