import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
  });

  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final jointPaint = Paint()
      ..color = const Color(0xFF34C759)
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;

    final bonePaint = Paint()
      ..color = const Color(0xFF34C759).withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final pose in poses) {
      // Draw bones
      for (final connection in _connections) {
        final from = pose.landmarks[connection.$1];
        final to = pose.landmarks[connection.$2];
        if (from == null || to == null) continue;
        if (from.likelihood < 0.5 || to.likelihood < 0.5) continue;
        canvas.drawLine(
          _translate(from.x, from.y, size),
          _translate(to.x, to.y, size),
          bonePaint,
        );
      }

      // Draw joints
      for (final lm in pose.landmarks.values) {
        if (lm.likelihood < 0.5) continue;
        canvas.drawCircle(_translate(lm.x, lm.y, size), 5, jointPaint);
      }
    }
  }

  Offset _translate(double x, double y, Size canvasSize) {
    // Flip for front camera
    final flippedX = cameraLensDirection == CameraLensDirection.front
        ? imageSize.width - x
        : x;

    final scaleX = canvasSize.width / _rotatedWidth;
    final scaleY = canvasSize.height / _rotatedHeight;

    // Account for 90/270 degree rotations
    if (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) {
      return Offset(y * scaleX, flippedX * scaleY);
    }
    return Offset(flippedX * scaleX, y * scaleY);
  }

  double get _rotatedWidth =>
      (rotation == InputImageRotation.rotation90deg ||
              rotation == InputImageRotation.rotation270deg)
          ? imageSize.height
          : imageSize.width;

  double get _rotatedHeight =>
      (rotation == InputImageRotation.rotation90deg ||
              rotation == InputImageRotation.rotation270deg)
          ? imageSize.width
          : imageSize.height;

  @override
  bool shouldRepaint(PosePainter oldDelegate) => true;
}

// Skeleton connections
const _connections = [
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
  (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
  (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
  (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
  (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
  (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
  (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
  (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
  (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
  (PoseLandmarkType.nose, PoseLandmarkType.leftShoulder),
  (PoseLandmarkType.nose, PoseLandmarkType.rightShoulder),
];

// Elbow angle in degrees: angle at [mid] between [first]-[mid]-[last]
double elbowAngle(
  PoseLandmark first,
  PoseLandmark mid,
  PoseLandmark last,
) {
  final v1x = first.x - mid.x;
  final v1y = first.y - mid.y;
  final v2x = last.x - mid.x;
  final v2y = last.y - mid.y;
  final dot = v1x * v2x + v1y * v2y;
  final mag = math.sqrt(v1x * v1x + v1y * v1y) *
      math.sqrt(v2x * v2x + v2y * v2y);
  if (mag == 0) return 0;
  return math.acos((dot / mag).clamp(-1.0, 1.0)) * 180 / math.pi;
}
