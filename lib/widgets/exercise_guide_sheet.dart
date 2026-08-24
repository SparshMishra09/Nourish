import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/exercise_guide.dart';
import '../models/workout.dart';

Future<void> showExerciseGuideSheet(
  BuildContext context,
  ExerciseItem exercise,
) async {
  final guide = ExerciseGuideCatalog.forName(exercise.name);
  if (guide == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppPalette.ink.withValues(alpha: 0.54),
    builder: (_) => _ExerciseGuideSheet(exercise: exercise, guide: guide),
  );
}

class _ExerciseGuideSheet extends StatefulWidget {
  const _ExerciseGuideSheet({required this.exercise, required this.guide});

  final ExerciseItem exercise;
  final ExerciseGuide guide;

  @override
  State<_ExerciseGuideSheet> createState() => _ExerciseGuideSheetState();
}

class _ExerciseGuideSheetState extends State<_ExerciseGuideSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _playing = !_playing;
      if (_playing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.94,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppPalette.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppPalette.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppPalette.lime,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Text(
                            widget.exercise.icon,
                            style: const TextStyle(fontSize: 25),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.exercise.name,
                                style: context.text.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.exercise.detail} · ${widget.exercise.focus}',
                                style: const TextStyle(
                                  color: AppPalette.muted,
                                  fontSize: 12.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close form guide',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _MotionStage(
                      motion: widget.guide.motion,
                      controller: _controller,
                      playing: _playing,
                      onTogglePlayback: _togglePlayback,
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(
                          Icons.offline_bolt_rounded,
                          color: AppPalette.mint,
                          size: 18,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Nourish Form Loop · built in and available offline',
                            style: TextStyle(
                              color: AppPalette.muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _InstructionStep(
                      number: '01',
                      title: 'Set your position',
                      body: widget.guide.setup,
                      color: AppPalette.violet,
                    ),
                    const SizedBox(height: 10),
                    _InstructionStep(
                      number: '02',
                      title: 'Make the movement',
                      body: widget.guide.action,
                      color: AppPalette.coral,
                    ),
                    const SizedBox(height: 10),
                    _InstructionStep(
                      number: '03',
                      title: 'Match your breath',
                      body: widget.guide.breathing,
                      color: AppPalette.mint,
                    ),
                    const SizedBox(height: 22),
                    Text('Form checkpoints', style: context.text.titleLarge),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.guide.cues
                          .map(
                            (cue) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppPalette.line),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: AppPalette.mint,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    cue,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppPalette.coral.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppPalette.coral.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.visibility_off_outlined,
                            color: AppPalette.coral,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Common mistake',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.guide.avoid,
                                  style: const TextStyle(
                                    color: AppPalette.muted,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Use a pain-free range and stop for sharp pain, dizziness, numbness, or unusual discomfort. A form loop is educational and does not replace personal medical or coaching advice.',
                      style: TextStyle(
                        color: AppPalette.muted,
                        fontSize: 10.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotionStage extends StatelessWidget {
  const _MotionStage({
    required this.motion,
    required this.controller,
    required this.playing,
    required this.onTogglePlayback,
  });

  final ExerciseMotion motion;
  final AnimationController controller;
  final bool playing;
  final VoidCallback onTogglePlayback;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.55,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF13201D), Color(0xFF09110F)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (_, _) => CustomPaint(
                    painter: ExerciseMotionPainter(
                      motion: motion,
                      progress: Curves.easeInOutCubic.transform(
                        controller.value,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 15,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (_, _) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      controller.value < 0.45 ? 'SETUP' : 'MOVE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Semantics(
                  button: true,
                  label: playing ? 'Pause form loop' : 'Play form loop',
                  child: InkWell(
                    onTap: onTogglePlayback,
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppPalette.lime,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: AppPalette.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.number,
    required this.title,
    required this.body,
    required this.color,
  });

  final String number;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: 12,
                    height: 1.42,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseMotionPainter extends CustomPainter {
  ExerciseMotionPainter({required this.motion, required this.progress});

  final ExerciseMotion motion;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final frames = _framesFor(motion);
    final pose = _Pose.lerp(frames.start, frames.end, progress);
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (var x = 0.12; x < 1; x += 0.12) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        gridPaint,
      );
    }
    for (var y = 0.2; y < 1; y += 0.2) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        gridPaint,
      );
    }

    final groundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * frames.ground),
      Offset(size.width * 0.92, size.height * frames.ground),
      groundPaint,
    );

    if (motion == ExerciseMotion.inclinePushUp) {
      final bench = Paint()
        ..color = AppPalette.violet.withValues(alpha: 0.8)
        ..strokeWidth = size.width * 0.018
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(size.width * 0.68, size.height * 0.51),
        Offset(size.width * 0.86, size.height * 0.51),
        bench,
      );
      canvas.drawLine(
        Offset(size.width * 0.8, size.height * 0.51),
        Offset(size.width * 0.8, size.height * 0.86),
        bench,
      );
    }

    _drawPose(
      canvas,
      size,
      frames.start,
      color: Colors.white.withValues(alpha: 0.1),
      jointColor: Colors.transparent,
      widthFactor: 0.018,
    );
    _drawPose(
      canvas,
      size,
      pose,
      color: Colors.white,
      jointColor: AppPalette.lime,
      widthFactor: 0.024,
    );

    if (_usesWeights(motion)) {
      final weightPaint = Paint()
        ..color = AppPalette.coral
        ..strokeWidth = size.width * 0.026
        ..strokeCap = StrokeCap.round;
      for (final hand in [pose.leftHand, pose.rightHand]) {
        final point = _scaled(hand, size);
        canvas.drawLine(
          point.translate(-size.width * 0.018, 0),
          point.translate(size.width * 0.018, 0),
          weightPaint,
        );
      }
    }

    final pulse = (math.sin(progress * math.pi) * 0.5) + 0.5;
    final pulsePaint = Paint()
      ..color = AppPalette.lime.withValues(alpha: 0.13 + pulse * 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      _scaled(pose.hip, size),
      size.width * (0.035 + pulse * 0.009),
      pulsePaint,
    );
  }

  void _drawPose(
    Canvas canvas,
    Size size,
    _Pose pose, {
    required Color color,
    required Color jointColor,
    required double widthFactor,
  }) {
    final limbPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * widthFactor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    void path(List<Offset> points) {
      final line = Path()
        ..moveTo(
          _scaled(points.first, size).dx,
          _scaled(points.first, size).dy,
        );
      for (final point in points.skip(1)) {
        final scaled = _scaled(point, size);
        line.lineTo(scaled.dx, scaled.dy);
      }
      canvas.drawPath(line, limbPaint);
    }

    path([pose.neck, pose.hip]);
    path([pose.neck, pose.leftElbow, pose.leftHand]);
    path([pose.neck, pose.rightElbow, pose.rightHand]);
    path([pose.hip, pose.leftKnee, pose.leftFoot]);
    path([pose.hip, pose.rightKnee, pose.rightFoot]);
    canvas.drawCircle(_scaled(pose.head, size), size.width * 0.037, headPaint);

    if (jointColor != Colors.transparent) {
      final jointPaint = Paint()..color = jointColor;
      for (final point in [
        pose.leftElbow,
        pose.rightElbow,
        pose.leftKnee,
        pose.rightKnee,
      ]) {
        canvas.drawCircle(_scaled(point, size), size.width * 0.009, jointPaint);
      }
    }
  }

  bool _usesWeights(ExerciseMotion motion) => switch (motion) {
    ExerciseMotion.dumbbellRow ||
    ExerciseMotion.shoulderPress ||
    ExerciseMotion.hipHinge => true,
    _ => false,
  };

  Offset _scaled(Offset point, Size size) =>
      Offset(point.dx * size.width, point.dy * size.height);

  @override
  bool shouldRepaint(covariant ExerciseMotionPainter oldDelegate) =>
      oldDelegate.motion != motion || oldDelegate.progress != progress;
}

class _MotionFrames {
  const _MotionFrames(this.start, this.end, {this.ground = 0.88});

  final _Pose start;
  final _Pose end;
  final double ground;
}

class _Pose {
  const _Pose({
    required this.head,
    required this.neck,
    required this.leftElbow,
    required this.leftHand,
    required this.rightElbow,
    required this.rightHand,
    required this.hip,
    required this.leftKnee,
    required this.leftFoot,
    required this.rightKnee,
    required this.rightFoot,
  });

  final Offset head;
  final Offset neck;
  final Offset leftElbow;
  final Offset leftHand;
  final Offset rightElbow;
  final Offset rightHand;
  final Offset hip;
  final Offset leftKnee;
  final Offset leftFoot;
  final Offset rightKnee;
  final Offset rightFoot;

  static _Pose lerp(_Pose a, _Pose b, double t) => _Pose(
    head: Offset.lerp(a.head, b.head, t)!,
    neck: Offset.lerp(a.neck, b.neck, t)!,
    leftElbow: Offset.lerp(a.leftElbow, b.leftElbow, t)!,
    leftHand: Offset.lerp(a.leftHand, b.leftHand, t)!,
    rightElbow: Offset.lerp(a.rightElbow, b.rightElbow, t)!,
    rightHand: Offset.lerp(a.rightHand, b.rightHand, t)!,
    hip: Offset.lerp(a.hip, b.hip, t)!,
    leftKnee: Offset.lerp(a.leftKnee, b.leftKnee, t)!,
    leftFoot: Offset.lerp(a.leftFoot, b.leftFoot, t)!,
    rightKnee: Offset.lerp(a.rightKnee, b.rightKnee, t)!,
    rightFoot: Offset.lerp(a.rightFoot, b.rightFoot, t)!,
  );
}

const _stand = _Pose(
  head: Offset(0.5, 0.16),
  neck: Offset(0.5, 0.27),
  leftElbow: Offset(0.43, 0.42),
  leftHand: Offset(0.44, 0.57),
  rightElbow: Offset(0.57, 0.42),
  rightHand: Offset(0.56, 0.57),
  hip: Offset(0.5, 0.56),
  leftKnee: Offset(0.45, 0.72),
  leftFoot: Offset(0.42, 0.88),
  rightKnee: Offset(0.55, 0.72),
  rightFoot: Offset(0.58, 0.88),
);

_MotionFrames _framesFor(ExerciseMotion motion) => switch (motion) {
  ExerciseMotion.pushUp => const _MotionFrames(
    _Pose(
      head: Offset(0.72, 0.39),
      neck: Offset(0.64, 0.43),
      leftElbow: Offset(0.69, 0.57),
      leftHand: Offset(0.72, 0.76),
      rightElbow: Offset(0.66, 0.58),
      rightHand: Offset(0.69, 0.76),
      hip: Offset(0.42, 0.54),
      leftKnee: Offset(0.29, 0.62),
      leftFoot: Offset(0.15, 0.73),
      rightKnee: Offset(0.3, 0.64),
      rightFoot: Offset(0.17, 0.75),
    ),
    _Pose(
      head: Offset(0.71, 0.59),
      neck: Offset(0.63, 0.6),
      leftElbow: Offset(0.61, 0.69),
      leftHand: Offset(0.72, 0.76),
      rightElbow: Offset(0.58, 0.68),
      rightHand: Offset(0.69, 0.76),
      hip: Offset(0.42, 0.64),
      leftKnee: Offset(0.29, 0.68),
      leftFoot: Offset(0.15, 0.73),
      rightKnee: Offset(0.3, 0.7),
      rightFoot: Offset(0.17, 0.75),
    ),
  ),
  ExerciseMotion.inclinePushUp => const _MotionFrames(
    _Pose(
      head: Offset(0.67, 0.27),
      neck: Offset(0.62, 0.33),
      leftElbow: Offset(0.67, 0.39),
      leftHand: Offset(0.72, 0.5),
      rightElbow: Offset(0.65, 0.4),
      rightHand: Offset(0.75, 0.5),
      hip: Offset(0.43, 0.5),
      leftKnee: Offset(0.32, 0.65),
      leftFoot: Offset(0.2, 0.86),
      rightKnee: Offset(0.34, 0.66),
      rightFoot: Offset(0.23, 0.86),
    ),
    _Pose(
      head: Offset(0.7, 0.4),
      neck: Offset(0.63, 0.43),
      leftElbow: Offset(0.62, 0.5),
      leftHand: Offset(0.72, 0.5),
      rightElbow: Offset(0.61, 0.53),
      rightHand: Offset(0.75, 0.5),
      hip: Offset(0.43, 0.56),
      leftKnee: Offset(0.32, 0.68),
      leftFoot: Offset(0.2, 0.86),
      rightKnee: Offset(0.34, 0.69),
      rightFoot: Offset(0.23, 0.86),
    ),
  ),
  ExerciseMotion.pikePushUp => const _MotionFrames(
    _Pose(
      head: Offset(0.67, 0.5),
      neck: Offset(0.61, 0.48),
      leftElbow: Offset(0.68, 0.61),
      leftHand: Offset(0.72, 0.78),
      rightElbow: Offset(0.65, 0.62),
      rightHand: Offset(0.69, 0.78),
      hip: Offset(0.43, 0.3),
      leftKnee: Offset(0.31, 0.52),
      leftFoot: Offset(0.18, 0.79),
      rightKnee: Offset(0.33, 0.53),
      rightFoot: Offset(0.21, 0.8),
    ),
    _Pose(
      head: Offset(0.71, 0.7),
      neck: Offset(0.63, 0.62),
      leftElbow: Offset(0.6, 0.7),
      leftHand: Offset(0.72, 0.78),
      rightElbow: Offset(0.57, 0.69),
      rightHand: Offset(0.69, 0.78),
      hip: Offset(0.43, 0.34),
      leftKnee: Offset(0.31, 0.54),
      leftFoot: Offset(0.18, 0.79),
      rightKnee: Offset(0.33, 0.55),
      rightFoot: Offset(0.21, 0.8),
    ),
  ),
  ExerciseMotion.dumbbellRow => const _MotionFrames(
    _Pose(
      head: Offset(0.68, 0.3),
      neck: Offset(0.61, 0.34),
      leftElbow: Offset(0.7, 0.48),
      leftHand: Offset(0.76, 0.62),
      rightElbow: Offset(0.55, 0.52),
      rightHand: Offset(0.51, 0.69),
      hip: Offset(0.43, 0.48),
      leftKnee: Offset(0.35, 0.66),
      leftFoot: Offset(0.27, 0.87),
      rightKnee: Offset(0.53, 0.67),
      rightFoot: Offset(0.61, 0.87),
    ),
    _Pose(
      head: Offset(0.68, 0.3),
      neck: Offset(0.61, 0.34),
      leftElbow: Offset(0.7, 0.48),
      leftHand: Offset(0.76, 0.62),
      rightElbow: Offset(0.47, 0.38),
      rightHand: Offset(0.52, 0.49),
      hip: Offset(0.43, 0.48),
      leftKnee: Offset(0.35, 0.66),
      leftFoot: Offset(0.27, 0.87),
      rightKnee: Offset(0.53, 0.67),
      rightFoot: Offset(0.61, 0.87),
    ),
  ),
  ExerciseMotion.shoulderPress => const _MotionFrames(
    _Pose(
      head: Offset(0.5, 0.18),
      neck: Offset(0.5, 0.29),
      leftElbow: Offset(0.37, 0.37),
      leftHand: Offset(0.43, 0.28),
      rightElbow: Offset(0.63, 0.37),
      rightHand: Offset(0.57, 0.28),
      hip: Offset(0.5, 0.56),
      leftKnee: Offset(0.45, 0.72),
      leftFoot: Offset(0.42, 0.88),
      rightKnee: Offset(0.55, 0.72),
      rightFoot: Offset(0.58, 0.88),
    ),
    _Pose(
      head: Offset(0.5, 0.18),
      neck: Offset(0.5, 0.29),
      leftElbow: Offset(0.43, 0.18),
      leftHand: Offset(0.44, 0.05),
      rightElbow: Offset(0.57, 0.18),
      rightHand: Offset(0.56, 0.05),
      hip: Offset(0.5, 0.56),
      leftKnee: Offset(0.45, 0.72),
      leftFoot: Offset(0.42, 0.88),
      rightKnee: Offset(0.55, 0.72),
      rightFoot: Offset(0.58, 0.88),
    ),
  ),
  ExerciseMotion.proneSweep => const _MotionFrames(
    _Pose(
      head: Offset(0.72, 0.62),
      neck: Offset(0.64, 0.64),
      leftElbow: Offset(0.54, 0.69),
      leftHand: Offset(0.42, 0.73),
      rightElbow: Offset(0.55, 0.66),
      rightHand: Offset(0.43, 0.69),
      hip: Offset(0.42, 0.68),
      leftKnee: Offset(0.29, 0.7),
      leftFoot: Offset(0.16, 0.72),
      rightKnee: Offset(0.29, 0.74),
      rightFoot: Offset(0.16, 0.77),
    ),
    _Pose(
      head: Offset(0.72, 0.62),
      neck: Offset(0.64, 0.64),
      leftElbow: Offset(0.73, 0.48),
      leftHand: Offset(0.82, 0.37),
      rightElbow: Offset(0.7, 0.45),
      rightHand: Offset(0.78, 0.32),
      hip: Offset(0.42, 0.68),
      leftKnee: Offset(0.29, 0.7),
      leftFoot: Offset(0.16, 0.72),
      rightKnee: Offset(0.29, 0.74),
      rightFoot: Offset(0.16, 0.77),
    ),
    ground: 0.78,
  ),
  ExerciseMotion.deadBug => const _MotionFrames(
    _Pose(
      head: Offset(0.75, 0.68),
      neck: Offset(0.68, 0.69),
      leftElbow: Offset(0.66, 0.48),
      leftHand: Offset(0.65, 0.31),
      rightElbow: Offset(0.71, 0.5),
      rightHand: Offset(0.72, 0.32),
      hip: Offset(0.46, 0.69),
      leftKnee: Offset(0.42, 0.48),
      leftFoot: Offset(0.55, 0.46),
      rightKnee: Offset(0.38, 0.52),
      rightFoot: Offset(0.5, 0.5),
    ),
    _Pose(
      head: Offset(0.75, 0.68),
      neck: Offset(0.68, 0.69),
      leftElbow: Offset(0.56, 0.66),
      leftHand: Offset(0.38, 0.74),
      rightElbow: Offset(0.71, 0.5),
      rightHand: Offset(0.72, 0.32),
      hip: Offset(0.46, 0.69),
      leftKnee: Offset(0.34, 0.68),
      leftFoot: Offset(0.2, 0.74),
      rightKnee: Offset(0.38, 0.52),
      rightFoot: Offset(0.5, 0.5),
    ),
    ground: 0.77,
  ),
  ExerciseMotion.squat => const _MotionFrames(
    _stand,
    _Pose(
      head: Offset(0.5, 0.29),
      neck: Offset(0.5, 0.4),
      leftElbow: Offset(0.4, 0.45),
      leftHand: Offset(0.47, 0.49),
      rightElbow: Offset(0.6, 0.45),
      rightHand: Offset(0.53, 0.49),
      hip: Offset(0.5, 0.63),
      leftKnee: Offset(0.35, 0.7),
      leftFoot: Offset(0.3, 0.88),
      rightKnee: Offset(0.65, 0.7),
      rightFoot: Offset(0.7, 0.88),
    ),
  ),
  ExerciseMotion.hipHinge => const _MotionFrames(
    _stand,
    _Pose(
      head: Offset(0.7, 0.36),
      neck: Offset(0.62, 0.39),
      leftElbow: Offset(0.62, 0.52),
      leftHand: Offset(0.61, 0.67),
      rightElbow: Offset(0.66, 0.52),
      rightHand: Offset(0.65, 0.67),
      hip: Offset(0.43, 0.53),
      leftKnee: Offset(0.4, 0.7),
      leftFoot: Offset(0.39, 0.88),
      rightKnee: Offset(0.52, 0.7),
      rightFoot: Offset(0.55, 0.88),
    ),
  ),
  ExerciseMotion.singleLegHinge => const _MotionFrames(
    _stand,
    _Pose(
      head: Offset(0.7, 0.36),
      neck: Offset(0.62, 0.4),
      leftElbow: Offset(0.7, 0.49),
      leftHand: Offset(0.78, 0.57),
      rightElbow: Offset(0.69, 0.45),
      rightHand: Offset(0.78, 0.5),
      hip: Offset(0.44, 0.53),
      leftKnee: Offset(0.42, 0.7),
      leftFoot: Offset(0.42, 0.88),
      rightKnee: Offset(0.29, 0.5),
      rightFoot: Offset(0.14, 0.46),
    ),
  ),
  ExerciseMotion.reverseLunge => const _MotionFrames(
    _stand,
    _Pose(
      head: Offset(0.51, 0.25),
      neck: Offset(0.51, 0.36),
      leftElbow: Offset(0.42, 0.48),
      leftHand: Offset(0.46, 0.6),
      rightElbow: Offset(0.6, 0.48),
      rightHand: Offset(0.56, 0.6),
      hip: Offset(0.5, 0.59),
      leftKnee: Offset(0.63, 0.69),
      leftFoot: Offset(0.7, 0.88),
      rightKnee: Offset(0.34, 0.75),
      rightFoot: Offset(0.25, 0.88),
    ),
  ),
  ExerciseMotion.bridge => const _MotionFrames(
    _Pose(
      head: Offset(0.77, 0.73),
      neck: Offset(0.69, 0.74),
      leftElbow: Offset(0.6, 0.78),
      leftHand: Offset(0.49, 0.82),
      rightElbow: Offset(0.61, 0.75),
      rightHand: Offset(0.5, 0.78),
      hip: Offset(0.45, 0.78),
      leftKnee: Offset(0.34, 0.58),
      leftFoot: Offset(0.2, 0.82),
      rightKnee: Offset(0.37, 0.6),
      rightFoot: Offset(0.23, 0.84),
    ),
    _Pose(
      head: Offset(0.77, 0.73),
      neck: Offset(0.69, 0.74),
      leftElbow: Offset(0.6, 0.78),
      leftHand: Offset(0.49, 0.82),
      rightElbow: Offset(0.61, 0.75),
      rightHand: Offset(0.5, 0.78),
      hip: Offset(0.46, 0.5),
      leftKnee: Offset(0.34, 0.58),
      leftFoot: Offset(0.2, 0.82),
      rightKnee: Offset(0.37, 0.6),
      rightFoot: Offset(0.23, 0.84),
    ),
    ground: 0.86,
  ),
  ExerciseMotion.calfRaise => const _MotionFrames(
    _stand,
    _Pose(
      head: Offset(0.5, 0.1),
      neck: Offset(0.5, 0.21),
      leftElbow: Offset(0.43, 0.36),
      leftHand: Offset(0.44, 0.51),
      rightElbow: Offset(0.57, 0.36),
      rightHand: Offset(0.56, 0.51),
      hip: Offset(0.5, 0.5),
      leftKnee: Offset(0.45, 0.66),
      leftFoot: Offset(0.43, 0.86),
      rightKnee: Offset(0.55, 0.66),
      rightFoot: Offset(0.57, 0.86),
    ),
  ),
  ExerciseMotion.sidePlank => const _MotionFrames(
    _Pose(
      head: Offset(0.7, 0.48),
      neck: Offset(0.64, 0.52),
      leftElbow: Offset(0.65, 0.66),
      leftHand: Offset(0.7, 0.78),
      rightElbow: Offset(0.59, 0.39),
      rightHand: Offset(0.56, 0.23),
      hip: Offset(0.43, 0.63),
      leftKnee: Offset(0.3, 0.7),
      leftFoot: Offset(0.17, 0.77),
      rightKnee: Offset(0.3, 0.67),
      rightFoot: Offset(0.17, 0.74),
    ),
    _Pose(
      head: Offset(0.7, 0.38),
      neck: Offset(0.64, 0.43),
      leftElbow: Offset(0.65, 0.62),
      leftHand: Offset(0.7, 0.78),
      rightElbow: Offset(0.59, 0.29),
      rightHand: Offset(0.56, 0.13),
      hip: Offset(0.43, 0.51),
      leftKnee: Offset(0.3, 0.62),
      leftFoot: Offset(0.17, 0.74),
      rightKnee: Offset(0.3, 0.59),
      rightFoot: Offset(0.17, 0.71),
    ),
  ),
  ExerciseMotion.shoulderTap => const _MotionFrames(
    _Pose(
      head: Offset(0.72, 0.42),
      neck: Offset(0.64, 0.46),
      leftElbow: Offset(0.69, 0.6),
      leftHand: Offset(0.72, 0.77),
      rightElbow: Offset(0.66, 0.61),
      rightHand: Offset(0.69, 0.77),
      hip: Offset(0.42, 0.57),
      leftKnee: Offset(0.29, 0.65),
      leftFoot: Offset(0.15, 0.75),
      rightKnee: Offset(0.3, 0.67),
      rightFoot: Offset(0.17, 0.78),
    ),
    _Pose(
      head: Offset(0.72, 0.42),
      neck: Offset(0.64, 0.46),
      leftElbow: Offset(0.69, 0.6),
      leftHand: Offset(0.72, 0.77),
      rightElbow: Offset(0.58, 0.43),
      rightHand: Offset(0.65, 0.46),
      hip: Offset(0.42, 0.57),
      leftKnee: Offset(0.29, 0.65),
      leftFoot: Offset(0.15, 0.75),
      rightKnee: Offset(0.3, 0.67),
      rightFoot: Offset(0.17, 0.78),
    ),
  ),
  ExerciseMotion.mountainClimber => const _MotionFrames(
    _Pose(
      head: Offset(0.72, 0.4),
      neck: Offset(0.64, 0.45),
      leftElbow: Offset(0.69, 0.6),
      leftHand: Offset(0.72, 0.77),
      rightElbow: Offset(0.66, 0.6),
      rightHand: Offset(0.69, 0.77),
      hip: Offset(0.43, 0.57),
      leftKnee: Offset(0.29, 0.66),
      leftFoot: Offset(0.15, 0.76),
      rightKnee: Offset(0.5, 0.7),
      rightFoot: Offset(0.59, 0.78),
    ),
    _Pose(
      head: Offset(0.72, 0.4),
      neck: Offset(0.64, 0.45),
      leftElbow: Offset(0.69, 0.6),
      leftHand: Offset(0.72, 0.77),
      rightElbow: Offset(0.66, 0.6),
      rightHand: Offset(0.69, 0.77),
      hip: Offset(0.43, 0.57),
      leftKnee: Offset(0.5, 0.7),
      leftFoot: Offset(0.59, 0.78),
      rightKnee: Offset(0.29, 0.66),
      rightFoot: Offset(0.15, 0.76),
    ),
  ),
  ExerciseMotion.standingClimber => _standingFrames(
    const _Pose(
      head: Offset(0.5, 0.16),
      neck: Offset(0.5, 0.27),
      leftElbow: Offset(0.43, 0.16),
      leftHand: Offset(0.4, 0.04),
      rightElbow: Offset(0.57, 0.16),
      rightHand: Offset(0.6, 0.04),
      hip: Offset(0.5, 0.56),
      leftKnee: Offset(0.43, 0.72),
      leftFoot: Offset(0.4, 0.88),
      rightKnee: Offset(0.57, 0.72),
      rightFoot: Offset(0.6, 0.88),
    ),
    const _Pose(
      head: Offset(0.5, 0.18),
      neck: Offset(0.5, 0.29),
      leftElbow: Offset(0.57, 0.42),
      leftHand: Offset(0.54, 0.54),
      rightElbow: Offset(0.58, 0.22),
      rightHand: Offset(0.62, 0.1),
      hip: Offset(0.5, 0.56),
      leftKnee: Offset(0.56, 0.5),
      leftFoot: Offset(0.62, 0.64),
      rightKnee: Offset(0.55, 0.72),
      rightFoot: Offset(0.58, 0.88),
    ),
  ),
  ExerciseMotion.fastFeet => _standingFrames(
    const _Pose(
      head: Offset(0.49, 0.22),
      neck: Offset(0.49, 0.33),
      leftElbow: Offset(0.39, 0.43),
      leftHand: Offset(0.46, 0.48),
      rightElbow: Offset(0.59, 0.43),
      rightHand: Offset(0.53, 0.49),
      hip: Offset(0.49, 0.58),
      leftKnee: Offset(0.4, 0.72),
      leftFoot: Offset(0.35, 0.86),
      rightKnee: Offset(0.57, 0.68),
      rightFoot: Offset(0.64, 0.82),
    ),
    const _Pose(
      head: Offset(0.51, 0.22),
      neck: Offset(0.51, 0.33),
      leftElbow: Offset(0.41, 0.43),
      leftHand: Offset(0.47, 0.49),
      rightElbow: Offset(0.61, 0.43),
      rightHand: Offset(0.54, 0.48),
      hip: Offset(0.51, 0.58),
      leftKnee: Offset(0.43, 0.68),
      leftFoot: Offset(0.36, 0.82),
      rightKnee: Offset(0.6, 0.72),
      rightFoot: Offset(0.65, 0.86),
    ),
  ),
  ExerciseMotion.stepJack => _standingFrames(
    _stand,
    const _Pose(
      head: Offset(0.5, 0.16),
      neck: Offset(0.5, 0.27),
      leftElbow: Offset(0.37, 0.15),
      leftHand: Offset(0.42, 0.03),
      rightElbow: Offset(0.63, 0.15),
      rightHand: Offset(0.58, 0.03),
      hip: Offset(0.5, 0.56),
      leftKnee: Offset(0.38, 0.7),
      leftFoot: Offset(0.27, 0.88),
      rightKnee: Offset(0.6, 0.72),
      rightFoot: Offset(0.64, 0.88),
    ),
  ),
  ExerciseMotion.kneeDrive || ExerciseMotion.powerMarch => _standingFrames(
    _stand,
    const _Pose(
      head: Offset(0.5, 0.14),
      neck: Offset(0.5, 0.25),
      leftElbow: Offset(0.4, 0.35),
      leftHand: Offset(0.48, 0.43),
      rightElbow: Offset(0.6, 0.2),
      rightHand: Offset(0.64, 0.09),
      hip: Offset(0.5, 0.54),
      leftKnee: Offset(0.42, 0.69),
      leftFoot: Offset(0.4, 0.88),
      rightKnee: Offset(0.62, 0.49),
      rightFoot: Offset(0.65, 0.65),
    ),
  ),
  ExerciseMotion.lateralReach => _standingFrames(
    _stand,
    const _Pose(
      head: Offset(0.66, 0.28),
      neck: Offset(0.61, 0.38),
      leftElbow: Offset(0.49, 0.46),
      leftHand: Offset(0.38, 0.54),
      rightElbow: Offset(0.7, 0.42),
      rightHand: Offset(0.78, 0.5),
      hip: Offset(0.55, 0.6),
      leftKnee: Offset(0.4, 0.71),
      leftFoot: Offset(0.28, 0.88),
      rightKnee: Offset(0.68, 0.68),
      rightFoot: Offset(0.75, 0.88),
    ),
  ),
  ExerciseMotion.birdDog => const _MotionFrames(
    _Pose(
      head: Offset(0.72, 0.48),
      neck: Offset(0.64, 0.52),
      leftElbow: Offset(0.67, 0.64),
      leftHand: Offset(0.68, 0.78),
      rightElbow: Offset(0.62, 0.65),
      rightHand: Offset(0.63, 0.78),
      hip: Offset(0.43, 0.57),
      leftKnee: Offset(0.38, 0.72),
      leftFoot: Offset(0.31, 0.79),
      rightKnee: Offset(0.48, 0.72),
      rightFoot: Offset(0.42, 0.79),
    ),
    _Pose(
      head: Offset(0.72, 0.48),
      neck: Offset(0.64, 0.52),
      leftElbow: Offset(0.75, 0.45),
      leftHand: Offset(0.85, 0.42),
      rightElbow: Offset(0.62, 0.65),
      rightHand: Offset(0.63, 0.78),
      hip: Offset(0.43, 0.57),
      leftKnee: Offset(0.38, 0.72),
      leftFoot: Offset(0.31, 0.79),
      rightKnee: Offset(0.3, 0.55),
      rightFoot: Offset(0.14, 0.51),
    ),
  ),
  ExerciseMotion.hipSwitch => const _MotionFrames(
    _Pose(
      head: Offset(0.5, 0.18),
      neck: Offset(0.5, 0.3),
      leftElbow: Offset(0.39, 0.42),
      leftHand: Offset(0.32, 0.57),
      rightElbow: Offset(0.61, 0.42),
      rightHand: Offset(0.68, 0.57),
      hip: Offset(0.5, 0.58),
      leftKnee: Offset(0.35, 0.62),
      leftFoot: Offset(0.25, 0.8),
      rightKnee: Offset(0.56, 0.72),
      rightFoot: Offset(0.7, 0.79),
    ),
    _Pose(
      head: Offset(0.5, 0.18),
      neck: Offset(0.5, 0.3),
      leftElbow: Offset(0.39, 0.42),
      leftHand: Offset(0.32, 0.57),
      rightElbow: Offset(0.61, 0.42),
      rightHand: Offset(0.68, 0.57),
      hip: Offset(0.5, 0.58),
      leftKnee: Offset(0.44, 0.72),
      leftFoot: Offset(0.3, 0.79),
      rightKnee: Offset(0.65, 0.62),
      rightFoot: Offset(0.75, 0.8),
    ),
  ),
  ExerciseMotion.childPose => const _MotionFrames(
    _Pose(
      head: Offset(0.72, 0.5),
      neck: Offset(0.64, 0.52),
      leftElbow: Offset(0.73, 0.65),
      leftHand: Offset(0.79, 0.78),
      rightElbow: Offset(0.7, 0.65),
      rightHand: Offset(0.76, 0.78),
      hip: Offset(0.43, 0.62),
      leftKnee: Offset(0.34, 0.73),
      leftFoot: Offset(0.23, 0.79),
      rightKnee: Offset(0.39, 0.74),
      rightFoot: Offset(0.28, 0.81),
    ),
    _Pose(
      head: Offset(0.68, 0.68),
      neck: Offset(0.59, 0.65),
      leftElbow: Offset(0.69, 0.7),
      leftHand: Offset(0.8, 0.78),
      rightElbow: Offset(0.66, 0.72),
      rightHand: Offset(0.77, 0.8),
      hip: Offset(0.39, 0.67),
      leftKnee: Offset(0.34, 0.73),
      leftFoot: Offset(0.23, 0.79),
      rightKnee: Offset(0.39, 0.74),
      rightFoot: Offset(0.28, 0.81),
    ),
  ),
  ExerciseMotion.worldStretch => const _MotionFrames(
    _Pose(
      head: Offset(0.65, 0.38),
      neck: Offset(0.58, 0.42),
      leftElbow: Offset(0.64, 0.57),
      leftHand: Offset(0.68, 0.76),
      rightElbow: Offset(0.53, 0.56),
      rightHand: Offset(0.55, 0.76),
      hip: Offset(0.43, 0.56),
      leftKnee: Offset(0.59, 0.67),
      leftFoot: Offset(0.69, 0.85),
      rightKnee: Offset(0.3, 0.66),
      rightFoot: Offset(0.18, 0.85),
    ),
    _Pose(
      head: Offset(0.59, 0.32),
      neck: Offset(0.56, 0.42),
      leftElbow: Offset(0.64, 0.57),
      leftHand: Offset(0.68, 0.76),
      rightElbow: Offset(0.49, 0.25),
      rightHand: Offset(0.45, 0.08),
      hip: Offset(0.43, 0.56),
      leftKnee: Offset(0.59, 0.67),
      leftFoot: Offset(0.69, 0.85),
      rightKnee: Offset(0.3, 0.66),
      rightFoot: Offset(0.18, 0.85),
    ),
  ),
  ExerciseMotion.standingFlow => _standingFrames(
    const _Pose(
      head: Offset(0.5, 0.15),
      neck: Offset(0.5, 0.26),
      leftElbow: Offset(0.43, 0.14),
      leftHand: Offset(0.45, 0.03),
      rightElbow: Offset(0.57, 0.14),
      rightHand: Offset(0.55, 0.03),
      hip: Offset(0.5, 0.56),
      leftKnee: Offset(0.45, 0.72),
      leftFoot: Offset(0.42, 0.88),
      rightKnee: Offset(0.55, 0.72),
      rightFoot: Offset(0.58, 0.88),
    ),
    const _Pose(
      head: Offset(0.56, 0.69),
      neck: Offset(0.55, 0.58),
      leftElbow: Offset(0.53, 0.67),
      leftHand: Offset(0.51, 0.79),
      rightElbow: Offset(0.58, 0.66),
      rightHand: Offset(0.57, 0.79),
      hip: Offset(0.47, 0.51),
      leftKnee: Offset(0.43, 0.7),
      leftFoot: Offset(0.4, 0.88),
      rightKnee: Offset(0.54, 0.7),
      rightFoot: Offset(0.58, 0.88),
    ),
  ),
};

_MotionFrames _standingFrames(_Pose start, _Pose end) =>
    _MotionFrames(start, end);
