import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'signin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _maxWait = Duration(seconds: 8);

  late final VideoPlayerController _controller;
  Timer? _fallbackTimer;
  bool _navigated = false;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/animation/SeatNix-splash-animation.mp4',
    )..addListener(_onVideoUpdate);
    _controller.initialize().then((_) async {
      if (!mounted) return;
      await _controller.setVolume(0);
      await _controller.play();
      if (!mounted) return;
      setState(() => _videoReady = true);
    }).catchError((Object _) {
      if (mounted) _openNextScreen();
    });
    _fallbackTimer = Timer(_maxWait, _openNextScreen);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onVideoUpdate() {
    final value = _controller.value;
    if (!value.isInitialized || value.duration == Duration.zero) return;
    if (value.position >= value.duration) _openNextScreen();
  }

  void _openNextScreen() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _openNextScreenForSession();
  }

  Future<void> _openNextScreenForSession() async {
    SeatNixUser? user;
    try {
      user = await widget.authService.currentUser().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {
      if (!mounted) return;
      user = null;
    }
    if (!mounted) return;
    final next = user != null
        ? HomeScreen(authService: widget.authService)
        : SignInScreen(authService: widget.authService);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: ColoredBox(
          color: Colors.white,
          child: ClipRect(
            child: Center(
              child: _videoReady
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}
