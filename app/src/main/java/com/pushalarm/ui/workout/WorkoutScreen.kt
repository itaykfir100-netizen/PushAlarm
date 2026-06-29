package com.pushalarm.ui.workout

import android.graphics.PointF
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.pose.Pose
import com.google.mlkit.vision.pose.PoseDetection
import com.google.mlkit.vision.pose.PoseLandmark
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions
import com.pushalarm.ui.theme.*
import java.util.concurrent.Executors

@Composable
fun WorkoutScreen(
    viewModel: WorkoutViewModel,
    alarmId: Long,
    targetReps: Int,
    alarmLabel: String,
    onDismiss: () -> Unit,
) {
    LaunchedEffect(alarmId) { viewModel.init(alarmId, targetReps) }

    val repCount by viewModel.repCount.collectAsState()
    val isComplete by viewModel.isComplete.collectAsState()
    val currentPose by viewModel.currentPose.collectAsState()
    val elapsed by viewModel.elapsedSeconds.collectAsState()

    LaunchedEffect(isComplete) {
        if (isComplete) {
            kotlinx.coroutines.delay(2000)
            onDismiss()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BackgroundDark)
    ) {
        // Camera preview + skeleton overlay
        CameraWithPoseOverlay(
            pose = currentPose,
            onPoseDetected = viewModel::onPoseDetected,
            modifier = Modifier.fillMaxSize(),
        )

        // Dim overlay for readability
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black.copy(alpha = 0.35f))
        )

        // Top bar with alarm label and elapsed time
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
                .align(Alignment.TopCenter),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column {
                Text(
                    text = alarmLabel.ifEmpty { "Wake Up!" },
                    color = TextPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 20.sp,
                )
                Text(
                    text = formatElapsed(elapsed),
                    color = TextSecondary,
                    fontSize = 14.sp,
                )
            }
            if (!isComplete) {
                TextButton(
                    onClick = { viewModel.skipWorkout(); onDismiss() },
                ) {
                    Text("Skip", color = TextSecondary.copy(alpha = 0.6f))
                }
            }
        }

        // Rep counter in center-bottom
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 60.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (isComplete) {
                CompletionBadge()
            } else {
                RepCounter(current = repCount, target = targetReps)
            }
        }
    }
}

@Composable
private fun RepCounter(current: Int, target: Int) {
    val progress = (current.toFloat() / target).coerceIn(0f, 1f)

    Box(contentAlignment = Alignment.Center) {
        CircularProgressIndicator(
            progress = { progress },
            modifier = Modifier.size(220.dp),
            strokeWidth = 8.dp,
            color = GreenAccent,
            trackColor = SurfaceDark.copy(alpha = 0.6f),
        )
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "$current",
                color = TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 80.sp,
                lineHeight = 80.sp,
            )
            Text(
                text = "/ $target reps",
                color = GreenAccent,
                fontWeight = FontWeight.SemiBold,
                fontSize = 20.sp,
            )
        }
    }
}

@Composable
private fun CompletionBadge() {
    val scale by rememberInfiniteTransition(label = "pulse").animateFloat(
        initialValue = 1f, targetValue = 1.05f,
        animationSpec = infiniteRepeatable(tween(600), RepeatMode.Reverse),
        label = "scale"
    )
    Box(
        modifier = Modifier
            .size((220 * scale).dp)
            .background(GreenAccent.copy(alpha = 0.15f), CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("Done!", color = GreenAccent, fontWeight = FontWeight.Bold, fontSize = 52.sp)
            Text("Alarm dismissed", color = TextPrimary, fontSize = 18.sp)
        }
    }
}

@Composable
private fun CameraWithPoseOverlay(
    pose: Pose?,
    onPoseDetected: (Pose) -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val executor = remember { Executors.newSingleThreadExecutor() }
    var imageSize by remember { mutableStateOf(Pair(1, 1)) }
    var previewSize by remember { mutableStateOf(Pair(0, 0)) }

    val poseDetector = remember {
        val options = PoseDetectorOptions.Builder()
            .setDetectorMode(PoseDetectorOptions.STREAM_MODE)
            .build()
        PoseDetection.getClient(options)
    }

    DisposableEffect(Unit) {
        onDispose {
            poseDetector.close()
            executor.shutdown()
        }
    }

    Box(modifier = modifier) {
        AndroidView(
            factory = { ctx ->
                PreviewView(ctx).apply {
                    implementationMode = PreviewView.ImplementationMode.COMPATIBLE
                    scaleType = PreviewView.ScaleType.FILL_CENTER
                }
            },
            modifier = Modifier.fillMaxSize(),
            update = { previewView ->
                val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
                cameraProviderFuture.addListener({
                    val cameraProvider = cameraProviderFuture.get()
                    val preview = Preview.Builder().build().also {
                        it.surfaceProvider = previewView.surfaceProvider
                    }
                    val analysis = ImageAnalysis.Builder()
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                        .build()
                    analysis.setAnalyzer(executor) { imageProxy ->
                        val mediaImage = imageProxy.image
                        if (mediaImage != null) {
                            imageSize = Pair(imageProxy.width, imageProxy.height)
                            val image = InputImage.fromMediaImage(
                                mediaImage, imageProxy.imageInfo.rotationDegrees
                            )
                            poseDetector.process(image)
                                .addOnSuccessListener { onPoseDetected(it) }
                                .addOnCompleteListener { imageProxy.close() }
                        } else {
                            imageProxy.close()
                        }
                    }
                    val selector = CameraSelector.Builder()
                        .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
                        .build()
                    try {
                        cameraProvider.unbindAll()
                        cameraProvider.bindToLifecycle(lifecycleOwner, selector, preview, analysis)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }, ContextCompat.getMainExecutor(context))
            }
        )

        // Skeleton overlay
        if (pose != null) {
            Canvas(modifier = Modifier.fillMaxSize()) {
                val scaleX = size.width / imageSize.first.toFloat()
                val scaleY = size.height / imageSize.second.toFloat()

                fun landmark(type: Int): Offset? {
                    val lm = pose.getPoseLandmark(type) ?: return null
                    if (lm.inFrameLikelihood < 0.5f) return null
                    return Offset(lm.position.x * scaleX, lm.position.y * scaleY)
                }

                fun drawBone(a: Int, b: Int, color: Color = GreenAccent.copy(alpha = 0.85f)) {
                    val p1 = landmark(a) ?: return
                    val p2 = landmark(b) ?: return
                    drawLine(color, p1, p2, strokeWidth = 4.dp.toPx(), cap = StrokeCap.Round)
                }

                fun drawDot(type: Int, color: Color = GreenAccent) {
                    val p = landmark(type) ?: return
                    drawCircle(color, radius = 6.dp.toPx(), center = p)
                }

                // Torso
                drawBone(PoseLandmark.LEFT_SHOULDER, PoseLandmark.RIGHT_SHOULDER)
                drawBone(PoseLandmark.LEFT_HIP, PoseLandmark.RIGHT_HIP)
                drawBone(PoseLandmark.LEFT_SHOULDER, PoseLandmark.LEFT_HIP)
                drawBone(PoseLandmark.RIGHT_SHOULDER, PoseLandmark.RIGHT_HIP)

                // Arms
                drawBone(PoseLandmark.LEFT_SHOULDER, PoseLandmark.LEFT_ELBOW)
                drawBone(PoseLandmark.LEFT_ELBOW, PoseLandmark.LEFT_WRIST)
                drawBone(PoseLandmark.RIGHT_SHOULDER, PoseLandmark.RIGHT_ELBOW)
                drawBone(PoseLandmark.RIGHT_ELBOW, PoseLandmark.RIGHT_WRIST)

                // Legs
                drawBone(PoseLandmark.LEFT_HIP, PoseLandmark.LEFT_KNEE)
                drawBone(PoseLandmark.LEFT_KNEE, PoseLandmark.LEFT_ANKLE)
                drawBone(PoseLandmark.RIGHT_HIP, PoseLandmark.RIGHT_KNEE)
                drawBone(PoseLandmark.RIGHT_KNEE, PoseLandmark.RIGHT_ANKLE)

                // Dots on joints
                listOf(
                    PoseLandmark.LEFT_SHOULDER, PoseLandmark.RIGHT_SHOULDER,
                    PoseLandmark.LEFT_ELBOW, PoseLandmark.RIGHT_ELBOW,
                    PoseLandmark.LEFT_WRIST, PoseLandmark.RIGHT_WRIST,
                    PoseLandmark.LEFT_HIP, PoseLandmark.RIGHT_HIP,
                    PoseLandmark.LEFT_KNEE, PoseLandmark.RIGHT_KNEE,
                    PoseLandmark.LEFT_ANKLE, PoseLandmark.RIGHT_ANKLE,
                ).forEach { drawDot(it) }
            }
        }
    }
}

private fun formatElapsed(seconds: Int): String {
    val m = seconds / 60
    val s = seconds % 60
    return "%d:%02d".format(m, s)
}
