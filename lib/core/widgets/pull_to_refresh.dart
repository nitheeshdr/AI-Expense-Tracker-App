import 'package:flutter/material.dart';

import '../design/app_theme.dart';
import '../utils/haptics.dart';

/// A lightweight, Material-free pull-to-refresh. Listens to overscroll on a
/// scrollable child and reveals a custom spinner that triggers [onRefresh] once
/// pulled past the threshold.
class PullToRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  const PullToRefresh({super.key, required this.onRefresh, required this.child});

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh>
    with SingleTickerProviderStateMixin {
  double _drag = 0;
  bool _refreshing = false;
  static const _threshold = 78.0;
  bool _armed = false;

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  bool _onNotification(ScrollNotification n) {
    if (_refreshing) return false;
    if (n is OverscrollNotification && n.overscroll < 0) {
      setState(() => _drag = (_drag - n.overscroll).clamp(0, 140));
      if (_drag >= _threshold && !_armed) {
        _armed = true;
        Haptics.light();
      }
    } else if (n is ScrollUpdateNotification && n.metrics.pixels > 0) {
      if (_drag != 0) setState(() => _drag = 0);
      _armed = false;
    } else if (n is ScrollEndNotification) {
      if (_drag >= _threshold) {
        _trigger();
      } else {
        setState(() => _drag = 0);
        _armed = false;
      }
    }
    return false;
  }

  Future<void> _trigger() async {
    setState(() {
      _refreshing = true;
      _drag = _threshold * 0.7;
    });
    _spin.repeat();
    await widget.onRefresh();
    if (!mounted) return;
    _spin.stop();
    setState(() {
      _refreshing = false;
      _drag = 0;
      _armed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Stack(
      children: [
        if (_drag > 0)
          Positioned(
            top: _drag / 2 - 16,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: (_drag / _threshold).clamp(0, 1),
                child: RotationTransition(
                  turns: _refreshing
                      ? _spin
                      : AlwaysStoppedAnimation(_drag / 120),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.surface,
                      border: Border.all(color: c.hairline),
                    ),
                    child: Icon(Icons.refresh, color: c.accent, size: 18),
                  ),
                ),
              ),
            ),
          ),
        NotificationListener<ScrollNotification>(
          onNotification: _onNotification,
          child: AnimatedContainer(
            duration: _refreshing
                ? Duration.zero
                : const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, _drag, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
