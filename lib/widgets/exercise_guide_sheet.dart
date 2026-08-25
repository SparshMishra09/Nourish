import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/exercise_guide.dart';
import '../models/workout.dart';

Future<void> showExerciseGuideSheet(
  BuildContext context,
  ExerciseItem exercise,
) async {
  final guide = ExerciseGuideCatalog.forName(exercise.name);
  final demo = ExerciseGuideCatalog.demoForName(exercise.name);
  if (guide == null || demo == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppPalette.ink.withValues(alpha: 0.54),
    builder: (_) =>
        _ExerciseGuideSheet(exercise: exercise, guide: guide, demo: demo),
  );
}

class _ExerciseGuideSheet extends StatelessWidget {
  const _ExerciseGuideSheet({
    required this.exercise,
    required this.guide,
    required this.demo,
  });

  final ExerciseItem exercise;
  final ExerciseGuide guide;
  final ExerciseDemo demo;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.96,
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
                    _GuideHeader(exercise: exercise),
                    const SizedBox(height: 18),
                    _ExerciseDbMediaStage(
                      exerciseName: exercise.name,
                      mediaUrl: demo.mediaUrl,
                    ),
                    const SizedBox(height: 12),
                    _SourceBadge(sourceName: demo.sourceName),
                    const SizedBox(height: 22),
                    _InstructionStep(
                      number: '01',
                      title: 'Set your position',
                      body: guide.setup,
                      color: AppPalette.violet,
                    ),
                    const SizedBox(height: 10),
                    _InstructionStep(
                      number: '02',
                      title: 'Make the movement',
                      body: guide.action,
                      color: AppPalette.coral,
                    ),
                    const SizedBox(height: 10),
                    _InstructionStep(
                      number: '03',
                      title: 'Match your breath',
                      body: guide.breathing,
                      color: AppPalette.mint,
                    ),
                    const SizedBox(height: 22),
                    Text('Form checkpoints', style: context.text.titleLarge),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: guide.cues.map((cue) => _CueChip(cue)).toList(),
                    ),
                    const SizedBox(height: 14),
                    _MistakeCard(message: guide.avoid),
                    const SizedBox(height: 14),
                    const Text(
                      'Use a pain-free range and stop for sharp pain, dizziness, numbness, or unusual discomfort. The demonstration is educational and does not replace personal medical or coaching advice.',
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

class _GuideHeader extends StatelessWidget {
  const _GuideHeader({required this.exercise});

  final ExerciseItem exercise;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          child: Text(exercise.icon, style: const TextStyle(fontSize: 25)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exercise.name, style: context.text.headlineMedium),
              const SizedBox(height: 4),
              Text(
                '${exercise.detail} · ${exercise.focus}',
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
          tooltip: 'Close exercise demonstration',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _ExerciseDbMediaStage extends StatefulWidget {
  const _ExerciseDbMediaStage({
    required this.exerciseName,
    required this.mediaUrl,
  });

  final String exerciseName;
  final String mediaUrl;

  @override
  State<_ExerciseDbMediaStage> createState() => _ExerciseDbMediaStageState();
}

class _ExerciseDbMediaStageState extends State<_ExerciseDbMediaStage> {
  var _reloadToken = 0;

  Future<void> _retry() async {
    await CachedNetworkImage.evictFromCache(widget.mediaUrl);
    if (mounted) setState(() => _reloadToken++);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Professional demonstration of ${widget.exerciseName}',
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: ColoredBox(
            color: Colors.white,
            child: CachedNetworkImage(
              key: ValueKey('${widget.mediaUrl}#$_reloadToken'),
              imageUrl: widget.mediaUrl,
              fit: BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 220),
              filterQuality: FilterQuality.high,
              progressIndicatorBuilder: (_, _, progress) =>
                  _MediaLoading(progress: progress.progress),
              errorWidget: (_, _, _) => _MediaError(onRetry: _retry),
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaLoading extends StatelessWidget {
  const _MediaLoading({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF13201D), Color(0xFF09110F)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                value: progress,
                color: AppPalette.lime,
                backgroundColor: Colors.white12,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 13),
            const Text(
              'Loading professional demonstration…',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF0F4F1),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppPalette.muted,
                size: 38,
              ),
              const SizedBox(height: 10),
              const Text(
                'The demonstration could not load.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your workout is still available. Check your connection and try the demo again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppPalette.muted,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry demonstration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.sourceName});

  final String sourceName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppPalette.mint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppPalette.mint.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppPalette.mint, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ExerciseDB by AscendAPI · $sourceName · cached after loading',
              style: const TextStyle(
                color: AppPalette.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
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

class _CueChip extends StatelessWidget {
  const _CueChip(this.cue);

  final String cue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppPalette.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.coral.withValues(alpha: 0.24)),
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
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
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
    );
  }
}
