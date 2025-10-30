// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFF1F2933);
const Color _secondaryColor = Color(0xFF3E4C59);
const Color _surfaceColor = Colors.white;
const Color _textColor = Color(0xFF101828);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coin Flipper CAPTCHA',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const CoinFlipperCaptcha(),
    );
  }
}

class CoinFlipperCaptcha extends StatefulWidget {
  const CoinFlipperCaptcha({super.key});

  @override
  State<CoinFlipperCaptcha> createState() => _CoinFlipperCaptchaState();
}

class _CoinFlipperCaptchaState extends State<CoinFlipperCaptcha> {
  static const int _totalFlips = 8;
  static const int _maxCorrectAllowed = 4;
  static const double _successProbability =
      0.65; // Chance a flip counts as correct.
  // Jitter configuration (milliseconds)
  static const int _guessDelayBaseMs = 800;
  static const int _guessDelayJitterMs =
      1500; // Actual delay: base + [0,jitter).
  static const int _evalDelayBaseMs = 600;
  static const int _evalDelayJitterMs = 300;

  final Random _rng = Random();

  int _flipsDone = 0;
  int _correctGuesses = 0;
  int _playthroughs =
      0; // Counts completed games (success or fail) via reset action.
  bool _finalized =
      false; // True once a game has fully finished (fail or evaluation complete).
  bool _locked = false;
  bool _successReported = false;
  String _statusMessage = 'Predict each flip, but do not be too accurate.';
  int _sessionId = 0; // Used to invalidate delayed completion if game resets.
  bool _isFlipping = false; // Indicates an in-progress guess animation.
  _CoinSide? _lastGuess;
  bool? _lastWasCorrect;
  _CoinSide? _pendingGuess; // Guess currently being processed.

  void _handleGuess(_CoinSide side) {
    if (_locked || _isFlipping) return;

    setState(() {
      _isFlipping = true;
      _pendingGuess = side; // Keep previous _lastGuess visible until resolved.
      _statusMessage = 'Processing guess…';
    });

    final int thisSession = _sessionId;
    final int guessDelay =
        _guessDelayBaseMs + _rng.nextInt(_guessDelayJitterMs);
    Future.delayed(Duration(milliseconds: guessDelay), () {
      if (!mounted || _sessionId != thisSession) return;
      bool isCorrect = _rng.nextDouble() < _successProbability;

      // Forced failure logic for first two playthroughs:
      // We want the user to exceed _maxCorrectAllowed by the end.
      // If remaining flips equal the number needed to surpass the limit, force remaining guesses to be correct.
      if (_playthroughs < 2) {
        final int remaining = _totalFlips - _flipsDone;
        final int neededToFail = (_maxCorrectAllowed + 1) - _correctGuesses;
        // If we still need some correct flips to push over the limit and have exactly that many flips left, force correctness.
        if (neededToFail > 0 && remaining == neededToFail) {
          isCorrect =
              true; // lock in all remaining as correct -> will exceed limit.
        } else if (neededToFail > 0 && remaining < neededToFail) {
          // Not enough flips remain to exceed limit -> ensure at least one correctness now if possible.
          // Force correctness until we catch up to a position where remaining == neededToFail.
          isCorrect = true;
        }
      }
      setState(() {
        _flipsDone++;
        _lastGuess = _pendingGuess; // Update together with correctness.
        _lastWasCorrect = isCorrect;
        _pendingGuess = null;
        if (isCorrect) _correctGuesses++;
        _isFlipping = false;

        if (_correctGuesses > _maxCorrectAllowed) {
          _locked = true;
          _finalized = true; // Game ends early due to exceeding limit.
          _statusMessage =
              'Too accurate! Suspicious behavior detected. Restart please.';
          return;
        }

        if (_flipsDone >= _totalFlips) {
          _locked = true;
          final bool passed = _correctGuesses <= _maxCorrectAllowed;
          _statusMessage = 'Evaluating results…';
          final int endSession = _sessionId;
          final int evalDelay =
              _evalDelayBaseMs + _rng.nextInt(_evalDelayJitterMs);
          Future.delayed(Duration(milliseconds: evalDelay), () {
            if (!mounted || _sessionId != endSession) return;
            setState(() {
              if (passed) {
                _statusMessage = 'Success! You are delightfully imperfect.';
                _reportSuccess();
              } else {
                _statusMessage = 'Too accurate overall. Restart to try again.';
              }
              _finalized = true; // Mark completion after evaluation.
            });
          });
          return;
        }

        final int flipsRemaining = _totalFlips - _flipsDone;
        _statusMessage = 'Outcome recorded. $flipsRemaining left.';
      });
    });
  }

  void _resetGame() {
    if (!_finalized) return; // Ignore restart attempts until game finished.
    setState(() {
      _flipsDone = 0;
      _correctGuesses = 0;
      _locked = false;
      _successReported = false;
      _statusMessage = 'Predict each flip, but do not be too accurate.';
      _sessionId++; // Invalidate any pending delayed completion.
      _isFlipping = false;
      _lastGuess = null;
      _lastWasCorrect = null;
      _pendingGuess = null;
      if (_finalized) {
        // Increment playthrough count once per completed game.
        print('Playthrough completed: ${_playthroughs + 1}');
        _playthroughs++;
      }
      _finalized = false; // Reset finalized state for new game.
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int flipsRemaining = _totalFlips - _flipsDone;
    // Simplified UI: no accuracy or flip log.

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _primaryColor.withOpacity(0.25)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: _primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_statusMessage.startsWith('Evaluating')) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(_primaryColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Target: $_totalFlips flips | Correct limit: $_maxCorrectAllowed',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _secondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            _ProgressBar(
              total: _totalFlips,
              flipsDone: _flipsDone,
              correct: _correctGuesses,
              maxCorrectAllowed: _maxCorrectAllowed,
            ),
            const SizedBox(height: 12),
            Text(
              'Flips: $_flipsDone/$_totalFlips | Correct: $_correctGuesses | Remaining: $flipsRemaining',
              style: theme.textTheme.bodySmall?.copyWith(color: _textColor),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_locked || _isFlipping)
                        ? null
                        : () => _handleGuess(_CoinSide.heads),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _isFlipping && _pendingGuess == _CoinSide.heads
                          ? Row(
                              key: const ValueKey('headsLoading'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text('Heads…'),
                              ],
                            )
                          : const Text('Heads', key: ValueKey('headsBtn')),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: (_locked || _isFlipping)
                        ? null
                        : () => _handleGuess(_CoinSide.tails),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _isFlipping && _pendingGuess == _CoinSide.tails
                          ? Row(
                              key: const ValueKey('tailsLoading'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation(
                                      _primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text('Tails…'),
                              ],
                            )
                          : const Text('Tails', key: ValueKey('tailsBtn')),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_lastGuess != null && _lastWasCorrect != null)
              Text(
                _lastWasCorrect!
                    ? 'You guessed ${_lastGuess == _CoinSide.heads ? 'Heads' : 'Tails'} correctly.'
                    : 'Your ${_lastGuess == _CoinSide.heads ? 'Heads' : 'Tails'} guess was incorrect.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _lastWasCorrect!
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: _finalized
                  ? TextButton.icon(
                      onPressed: _resetGame,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Restart'),
                    )
                  : const SizedBox.shrink(),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _reportSuccess() {
    if (_successReported) {
      return;
    }

    _successReported = true;
    if (kIsWeb) {
      html.window.parent?.postMessage('success', '*');
    }
  }
}

// Removed _CoinSide enum; outcomes are purely probabilistic.
enum _CoinSide { heads, tails }

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.total,
    required this.flipsDone,
    required this.correct,
    required this.maxCorrectAllowed,
  });

  final int total;
  final int flipsDone;
  final int correct;
  final int maxCorrectAllowed;

  @override
  Widget build(BuildContext context) {
    // Width will expand to parent; draw layered bar.
    return LayoutBuilder(
      builder: (context, constraints) {
        final double fullWidth = constraints.maxWidth;
        // Avoid division by zero.
        final double progressRatio = total == 0 ? 0 : flipsDone / total;
        final double thresholdRatio = maxCorrectAllowed / total;

        final double progressWidth = fullWidth * progressRatio;
        // correctWidth replaced by segmented green/red calculations below.
        final double thresholdX = fullWidth * thresholdRatio;

        return SizedBox(
          height: 12,
          child: Stack(
            children: [
              // Background track
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Overall progress (gray overlay so remaining stands out)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: progressWidth,
                    decoration: BoxDecoration(color: const Color(0xFFD1D5DB)),
                  ),
                ),
              ),
              // Allowed correct flips segment (green) up to threshold.
              if (correct > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width:
                          min(correct, maxCorrectAllowed) / total * fullWidth,
                      decoration: BoxDecoration(color: Colors.green.shade500),
                    ),
                  ),
                ),
                // Overflow correct flips segment (red) beyond threshold.
                if (correct > maxCorrectAllowed)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          left: (maxCorrectAllowed / total * fullWidth),
                        ),
                        width:
                            (correct - maxCorrectAllowed) / total * fullWidth,
                        decoration: BoxDecoration(color: Colors.red.shade500),
                      ),
                    ),
                  ),
              ],
              // Threshold marker (red vertical line) at allowed correct flips limit.
              Positioned(
                left: thresholdX - 1, // center the 2px line
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

ThemeData _buildTheme() {
  final ThemeData base = ThemeData(useMaterial3: true);
  return base.copyWith(
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      onPrimary: Colors.white,
      secondary: _secondaryColor,
      onSecondary: Colors.white,
      surface: _surfaceColor,
      onSurface: _textColor,
    ),
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: base.textTheme.apply(
      bodyColor: _textColor,
      displayColor: _textColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryColor,
        side: const BorderSide(color: _secondaryColor),
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _secondaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryColor,
      linearTrackColor: Color(0xFFE5E7EB),
    ),
  );
}
