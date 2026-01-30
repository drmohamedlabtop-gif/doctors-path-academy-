// FEATURE: Implemented advanced gesture controls for the video player.
import 'dart:async';
import 'dart:math';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctors_path_academy/watermark_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, String>? videoQualities;
  final String? videoUrl;
  final String courseId;
  final String lectureId;

  VideoPlayerScreen({
    super.key,
    this.videoQualities,
    this.videoUrl,
    required this.courseId,
    required this.lectureId,
  }) : assert(videoUrl != null || (videoQualities != null && videoQualities.isNotEmpty));

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _errorOccurred = false;
  late String _currentQuality;
  String? _watermarkText;
  final Map<String, String> _qualities = {};

  Timer? _watermarkTimer;
  Alignment _watermarkAlignment = Alignment.topLeft;
  final _random = Random();
  int _watermarkCycleCounter = 0;

  // Gesture feedback state
  String _seekIndicatorText = '';
  IconData? _seekIndicatorIcon;
  bool _showSeekIndicator = false;
  Timer? _seekIndicatorTimer;
  bool _showSpeedIndicator = false;
  double _currentSpeed = 1.0;

  static const List<Alignment> _alignments = [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
    Alignment.center,
  ];

  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupWatermark();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    if (widget.videoUrl != null) {
      _qualities['Default'] = widget.videoUrl!;
    } else if (widget.videoQualities != null) {
      _qualities.addAll(widget.videoQualities!);
    }

    if (_qualities.isNotEmpty) {
      _currentQuality = _qualities.keys.first;
      _loadProgress().then((startAt) {
        if (mounted) {
          initializePlayer(_qualities[_currentQuality]!, startAt: startAt);
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorOccurred = true;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted || _chewieController == null || !_videoPlayerController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _videoPlayerController.setVolume(1.0);
      _chewieController?.play();
    } else {
      _chewieController?.pause();
      _videoPlayerController.pause();
      _videoPlayerController.setVolume(0.0);
    }
  }

  Future<void> _setupWatermark() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final username = user.email?.split('@').first ?? 'No Email';

    String? phoneNumber;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        phoneNumber = userDoc.data()?['phone'];
      }
    } catch (e) {
      // Failed to fetch phone number
    }

    if (!mounted) return;

    setState(() {
      _watermarkText = (phoneNumber != null && phoneNumber.isNotEmpty) ? phoneNumber : username;
    });

    _watermarkTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _watermarkAlignment = _alignments[_random.nextInt(_alignments.length)];
        _watermarkCycleCounter++;
        if (_watermarkCycleCounter > 10) _watermarkCycleCounter = 1;
        _watermarkText = (phoneNumber != null && phoneNumber.isNotEmpty && _watermarkCycleCounter <= 5) ? phoneNumber : username;
      });
    });
  }

  Future<void> initializePlayer(String videoUrl, {Duration startAt = Duration.zero}) async {
    if (videoUrl.isEmpty || !Uri.parse(videoUrl).isAbsolute) {
      if (mounted) setState(() { _isLoading = false; _errorOccurred = true; });
      return;
    }

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    try {
      await _videoPlayerController.initialize();
      _createChewieController(startAt: startAt);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorOccurred = true; });
    }
  }

  void _createChewieController({Duration startAt = Duration.zero}) {
    _chewieController?.dispose();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      startAt: startAt,
      showControlsOnInitialize: true,
      allowedScreenSleep: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.blue,
        bufferedColor: Colors.grey.shade600,
        backgroundColor: Colors.grey.shade300,
      ),
      placeholder: Container(color: Colors.black),
      autoInitialize: true,
      allowPlaybackSpeedChanging: true,
      playbackSpeeds: const [0.5, 1.0, 1.25, 1.5, 1.75, 2.0],
      additionalOptions: _qualities.length > 1 ? (context) {
        return _qualities.keys.map((quality) {
          return OptionItem(
            onTap: (_) {
              Navigator.pop(context);
              _onQualitySelected(quality);
            },
            iconData: Icons.hd,
            title: quality,
            subtitle: _currentQuality == quality ? ' (Current)' : null,
          );
        }).toList();
      } : null,
    );

    _startProgressTimer();
  }

  Future<void> _onQualitySelected(String newQuality) async {
    if (_currentQuality == newQuality) return;

    if (mounted) setState(() => _isLoading = true);

    final newUrl = _qualities[newQuality]!;
    final oldPosition = await _videoPlayerController.position ?? Duration.zero;

    await _videoPlayerController.pause();
    _stopProgressTimer();

    final newVideoController = VideoPlayerController.networkUrl(Uri.parse(newUrl));

    try {
      await newVideoController.initialize();
      await _videoPlayerController.dispose();
      _chewieController?.dispose();

      _videoPlayerController = newVideoController;
      _createChewieController(startAt: oldPosition);

      if (mounted) {
        setState(() {
          _currentQuality = newQuality;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorOccurred = true);
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || !_videoPlayerController.value.isInitialized) return;
      final position = await _videoPlayerController.position;
      if (position != null) await _saveProgress(position);
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
  }

  Future<void> _saveProgress(Duration progress) async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'video_progress_${widget.courseId}_${widget.lectureId}';
    await prefs.setInt(key, progress.inSeconds);

    final duration = _videoPlayerController.value.duration;
    if (duration != Duration.zero && progress.inSeconds >= duration.inSeconds * 0.9) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('watched_lectures')
            .doc(widget.lectureId)
            .set({'courseId': widget.courseId, 'watchedAt': Timestamp.now()}, SetOptions(merge: true));
      }
    }
  }

  Future<Duration> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'video_progress_${widget.courseId}_${widget.lectureId}';
    final savedSeconds = prefs.getInt(key) ?? 0;
    return Duration(seconds: savedSeconds);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopProgressTimer();
    _watermarkTimer?.cancel();
    _seekIndicatorTimer?.cancel();
    if (_videoPlayerController.value.isInitialized) {
        _videoPlayerController.position.then((p) { if(p != null) _saveProgress(p); });
    }
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // ======== Gesture Handling Logic ======== //

  void _showSeekFeedback(IconData icon, String text) {
    _seekIndicatorTimer?.cancel();
    if (mounted) {
      setState(() {
        _seekIndicatorIcon = icon;
        _seekIndicatorText = text;
        _showSeekIndicator = true;
      });
      _seekIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _showSeekIndicator = false;
          });
        }
      });
    }
  }

  Widget _buildGestureDetectorOverlay() {
    return GestureDetector(
      onDoubleTapDown: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final tapPosition = details.globalPosition.dx;
        const seekDuration = Duration(seconds: 10);
        final currentPosition = _videoPlayerController.value.position;
        final totalDuration = _videoPlayerController.value.duration;

        if (tapPosition < screenWidth * 0.35) { // Left 35% of the screen
          final newPosition = currentPosition - seekDuration;
          _videoPlayerController.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
          _showSeekFeedback(Icons.replay_10, '-10s');
        } else if (tapPosition > screenWidth * 0.65) { // Right 35% of the screen
          final newPosition = currentPosition + seekDuration;
          _videoPlayerController.seekTo(newPosition > totalDuration ? totalDuration : newPosition);
          _showSeekFeedback(Icons.forward_10, '+10s');
        } else { // Middle of the screen
          if (_videoPlayerController.value.isPlaying) {
            _chewieController?.pause();
          } else {
            _chewieController?.play();
          }
        }
      },
      onDoubleTap: () { /* Required for onDoubleTapDown to work */ },
      onLongPressStart: (_) {
        _videoPlayerController.setPlaybackSpeed(2.0);
        setState(() {
          _currentSpeed = 2.0;
          _showSpeedIndicator = true;
        });
      },
      onLongPressEnd: (_) {
        _videoPlayerController.setPlaybackSpeed(1.0); // Reset to normal speed
        setState(() {
          _showSpeedIndicator = false;
          _currentSpeed = 1.0;
        });
      },
      behavior: HitTestBehavior.translucent, // Allows gestures to be detected on transparent areas
      child: const SizedBox.expand(), // Make the detector cover the whole screen
    );
  }

  Widget _buildSeekIndicator() {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _showSeekIndicator ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_seekIndicatorIcon != null)
                  Icon(_seekIndicatorIcon, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Text(_seekIndicatorText, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedIndicator() {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _showSpeedIndicator ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Text(
                '${_currentSpeed}x',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorOccurred || _chewieController == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Could not load video.\nCheck video URLs and internet connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      // Base video player
                      if (_chewieController != null) Chewie(controller: _chewieController!),
                      
                      // Watermark and Logo layers
                      if (_watermarkText != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: AnimatedAlign(
                            alignment: _watermarkAlignment,
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeInOut,
                            child: DynamicWatermark(text: _watermarkText!),
                          ),
                        ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Opacity(
                          opacity: 0.4,
                          child: Image.asset('assets/logo.png', width: 80),
                        ),
                      ),
                      
                      // Visual feedback indicators
                      _buildSeekIndicator(),
                      _buildSpeedIndicator(),
                      
                      // Overlay for custom gestures sits on top of everything
                      _buildGestureDetectorOverlay(),
                    ],
                  ),
      ),
    );
  }
}
