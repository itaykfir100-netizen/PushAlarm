import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../data/database_helper.dart';
import '../../models/workout_log.dart';
import '../../providers/stats_provider.dart';
import '../../services/alarm_service.dart';
import '../../theme/app_theme.dart';
import 'pose_painter.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key, required this.alarmId, required this.target});
  final int alarmId;
  final int target;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _camera;
  final PoseDetector _detector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );
  final _ringtone = FlutterRingtonePlayer();
  bool _isDetecting = false;
  bool _playingLocalSound = false;

  List<Pose> _poses = [];
  Size _imageSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;

  int _repCount = 0;
  _PushUpPhase _phase = _PushUpPhase.waiting;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initCamera();
    _startAlarmSound();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.stopImageStream();
    _controller?.dispose();
    _detector.close();
    if (_playingLocalSound) _ringtone.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _startAlarmSound() async {
    // A real alarm already plays audio in the background isolate (alarmCallback).
    // Only play here when coming from the simulate button (no active alarm key).
    if (await AlarmService.instance.hasActiveAlarm()) return;

    try {
      await _ringtone.playAlarm(looping: true, asAlarm: true);
      _playingLocalSound = true;
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      _camera!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _controller!.initialize();
    if (!mounted) return;

    setState(() {});
    _controller!.startImageStream(_processFrame);
  }

  void _processFrame(CameraImage image) {
    if (_isDetecting || _done) return;
    _isDetecting = true;

    final inputImage = _toInputImage(image);
    if (inputImage == null) {
      _isDetecting = false;
      return;
    }

    _detector.processImage(inputImage).then((poses) {
      if (!mounted) {
        _isDetecting = false;
        return;
      }

      // Compute rep state changes BEFORE setState to avoid nested setState.
      bool shouldComplete = false;
      int newRepCount = _repCount;
      _PushUpPhase newPhase = _phase;

      if (poses.isNotEmpty) {
        final result = _computeRepState(
          poses.first, _repCount, _phase, widget.target,
        );
        newRepCount = result.$1;
        newPhase = result.$2;
        shouldComplete = result.$3;
      }

      setState(() {
        _poses = poses;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        _repCount = newRepCount;
        _phase = newPhase;
      });

      if (shouldComplete && !_done) _onComplete();

      _isDetecting = false;
    }).catchError((_) {
      _isDetecting = false;
    });
  }

  // Pure function — no setState calls inside.
  // Returns (newRepCount, newPhase, targetReached).
  (int, _PushUpPhase, bool) _computeRepState(
    Pose pose,
    int currentReps,
    _PushUpPhase currentPhase,
    int target,
  ) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final lWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (lShoulder == null || lElbow == null || lWrist == null ||
        rShoulder == null || rElbow == null || rWrist == null) {
      return (currentReps, currentPhase, false);
    }

    final minLikelihood = [lShoulder, lElbow, lWrist, rShoulder, rElbow, rWrist]
        .map((l) => l.likelihood)
        .reduce((a, b) => a < b ? a : b);

    if (minLikelihood < 0.5) return (currentReps, currentPhase, false);

    final avgAngle =
        (elbowAngle(lShoulder, lElbow, lWrist) +
            elbowAngle(rShoulder, rElbow, rWrist)) /
        2;

    var reps = currentReps;
    var phase = currentPhase;

    if (avgAngle < 90 && phase != _PushUpPhase.down) {
      phase = _PushUpPhase.down;
    } else if (avgAngle > 160 && phase == _PushUpPhase.down) {
      phase = _PushUpPhase.up;
      reps++;
    }

    return (reps, phase, reps >= target);
  }

  Future<void> _onComplete() async {
    if (_done) return;
    _done = true;

    if (_playingLocalSound) {
      _ringtone.stop();
      _playingLocalSound = false;
    }
    await _controller?.stopImageStream();
    await AlarmService.instance.clearActiveAlarm();

    // Reschedule alarm for its next occurrence
    final alarm = await DatabaseHelper.instance.getAlarm(widget.alarmId);
    if (alarm != null && alarm.isEnabled) {
      await AlarmService.instance.scheduleAlarm(alarm);
    }

    await DatabaseHelper.instance.insertLog(WorkoutLog(
      alarmId: widget.alarmId,
      date: DateTime.now(),
      pushUpsCompleted: _repCount,
      targetPushUps: widget.target,
    ));

    if (!mounted) return;
    final statsProvider = context.read<StatsProvider>();
    final nav = Navigator.of(context);
    await statsProvider.load();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Alarm dismissed!',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'You did $_repCount push-ups. Keep it up!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nav.pop();
              nav.pop();
            },
            child: const Text('Done', style: TextStyle(color: kGreen)),
          ),
        ],
      ),
    );
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _camera;
    if (camera == null) return null;

    InputImageRotation rotation;
    if (Platform.isAndroid) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation)
          ?? InputImageRotation.rotation0deg;
    } else {
      rotation = InputImageRotation.rotation0deg;
    }
    _rotation = rotation;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || image.planes.isEmpty) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ctrl != null && ctrl.value.isInitialized)
            CameraPreview(ctrl),

          if (_poses.isNotEmpty && _imageSize != Size.zero)
            CustomPaint(
              painter: PosePainter(
                poses: _poses,
                imageSize: _imageSize,
                rotation: _rotation,
                cameraLensDirection: _camera?.lensDirection
                    ?? CameraLensDirection.front,
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_playingLocalSound) _ringtone.stop();
                          Navigator.maybePop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Goal: ${widget.target} reps',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(
                      vertical: 32, horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _repCount >= widget.target
                          ? kGreen
                          : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_repCount',
                        style: TextStyle(
                          fontSize: 96,
                          fontWeight: FontWeight.bold,
                          color: _repCount >= widget.target
                              ? kGreen
                              : Colors.white,
                          height: 1,
                        ),
                      ),
                      Text(
                        '/ ${widget.target} push-ups',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      _PhaseIndicator(phase: _phase),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Place phone on floor in front of you.\nGet into push-up position and begin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 12),

                // Testing shortcut — instantly completes the workout
                GestureDetector(
                  onTap: _done ? null : () {
                    setState(() => _repCount = widget.target);
                    _onComplete();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'Add ${widget.target} reps (test)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  const _PhaseIndicator({required this.phase});
  final _PushUpPhase phase;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (phase) {
      _PushUpPhase.waiting => ('Get into position', Colors.white60),
      _PushUpPhase.down    => ('DOWN ↓', const Color(0xFFFF9500)),
      _PushUpPhase.up      => ('UP ↑', kGreen),
    };
    return Text(
      label,
      style: TextStyle(
          color: color, fontSize: 16, fontWeight: FontWeight.w600),
    );
  }
}

enum _PushUpPhase { waiting, down, up }
