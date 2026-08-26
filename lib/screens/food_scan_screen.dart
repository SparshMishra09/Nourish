import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/app_theme.dart';
import '../models/food_analysis.dart';
import '../services/food_analysis_service.dart';
import '../widgets/brand_mark.dart';
import '../widgets/shared_ui.dart';

class FoodScanScreen extends StatefulWidget {
  const FoodScanScreen({
    super.key,
    required this.onLogMeal,
    this.analysisService,
  });

  final Future<void> Function(FoodAnalysis analysis) onLogMeal;
  final FoodAnalysisService? analysisService;

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen> {
  final _picker = ImagePicker();
  final _hintController = TextEditingController();
  late final FoodAnalysisService _analysisService;
  XFile? _image;
  FoodAnalysis? _analysis;
  double _portion = 1;
  bool _analyzing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analysisService = widget.analysisService ?? FoodAnalysisService();
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
      requestFullMetadata: false,
    );
    if (image == null || !mounted) return;
    setState(() {
      _image = image;
      _analysis = null;
      _portion = 1;
      _error = null;
    });
  }

  Future<void> _analyze() async {
    final image = _image;
    if (image == null) return;
    setState(() {
      _analyzing = true;
      _error = null;
      _analysis = null;
    });
    try {
      final bytes = await image.readAsBytes();
      final result = await _analysisService.analyze(
        imageBytes: bytes,
        mimeType: detectImageMimeType(bytes, filePath: image.path),
        contextHint: _hintController.text,
      );
      if (!mounted) return;
      setState(() => _analysis = result);
    } on FoodAnalysisException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      debugPrint('Could not read the selected food photo: $error');
      if (mounted) {
        setState(
          () => _error =
              'Nourish could not read this photo. Retake it with the app camera and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _addToToday() async {
    final analysis = _analysis;
    if (analysis == null || !analysis.isFood || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onLogMeal(analysis.scaled(_portion));
      if (!mounted) return;
      showAppMessage(context, '${analysis.mealName} added to today.');
      setState(() {
        _image = null;
        _analysis = null;
        _portion = 1;
        _hintController.clear();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save this meal. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('food-scan'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 14,
              20,
              0,
            ),
            child: const Row(
              children: [BrandMark(size: 42), Spacer(), _PrivacyBadge()],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Snap it.\nKnow what’s in it.',
                  style: context.text.displayMedium,
                ),
                const SizedBox(height: 9),
                const Text(
                  'Photograph the full plate—or keep a package’s exact brand and flavour clearly visible. Confirm the serving before it counts toward today.',
                  style: TextStyle(color: AppPalette.muted, height: 1.45),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _CaptureCard(
              image: _image,
              analyzing: _analyzing,
              onCamera: () => _pick(ImageSource.camera),
              onGallery: () => _pick(ImageSource.gallery),
            ),
          ),
        ),
        if (_image != null) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _hintController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Optional details for better accuracy',
                  hintText: 'e.g. brand, flavour, pack size or recipe details',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(
              child: FilledButton.icon(
                onPressed: _analyzing ? null : _analyze,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppPalette.ink,
                  foregroundColor: Colors.white,
                ),
                icon: _analyzing
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppPalette.lime,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  _analyzing
                      ? 'Identifying and checking sources…'
                      : 'Analyze this meal',
                ),
              ),
            ),
          ),
        ],
        if (_error != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(child: _ErrorCard(message: _error!)),
          ),
        if (_analysis != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 135),
            sliver: SliverToBoxAdapter(
              child: _AnalysisCard(
                analysis: _analysis!,
                portion: _portion,
                saving: _saving,
                onPortionChanged: (value) => setState(() => _portion = value),
                onAdd: _addToToday,
                onRetake: () => _pick(ImageSource.camera),
              ),
            ),
          )
        else
          const SliverToBoxAdapter(child: SizedBox(height: 135)),
      ],
    );
  }
}

class _PrivacyBadge extends StatelessWidget {
  const _PrivacyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.mint.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, size: 16, color: AppPalette.mint),
          SizedBox(width: 6),
          Text(
            'Photo not saved',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    required this.image,
    required this.analyzing,
    required this.onCamera,
    required this.onGallery,
  });

  final XFile? image;
  final bool analyzing;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppPalette.ink,
        borderRadius: BorderRadius.circular(31),
        boxShadow: [
          BoxShadow(
            color: AppPalette.ink.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Image.file(File(image!.path), fit: BoxFit.cover)
          else ...[
            Positioned(
              right: -45,
              top: -55,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: AppPalette.lime.withValues(alpha: 0.11),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.center_focus_strong_rounded,
                    color: AppPalette.lime,
                    size: 58,
                  ),
                  SizedBox(height: 13),
                  Text(
                    'Keep the food or label in frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Good light · exact variant · no blur',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          if (image != null)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  stops: const [0.55, 1],
                ),
              ),
            ),
          if (analyzing) const Positioned.fill(child: ScannerLoadingOverlay()),
          if (!analyzing)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onCamera,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppPalette.lime,
                        foregroundColor: AppPalette.ink,
                      ),
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: Text(image == null ? 'Take photo' : 'Retake'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: onGallery,
                    tooltip: 'Choose from gallery',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      backgroundColor: Colors.white,
                      foregroundColor: AppPalette.ink,
                    ),
                    icon: const Icon(Icons.photo_library_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerLoadingOverlay extends StatefulWidget {
  const ScannerLoadingOverlay({super.key});

  @override
  State<ScannerLoadingOverlay> createState() => _ScannerLoadingOverlayState();
}

class _ScannerLoadingOverlayState extends State<ScannerLoadingOverlay>
    with SingleTickerProviderStateMixin {
  static const _stages = [
    'Reading the package',
    'Matching the exact product',
    'Checking live nutrition sources',
    'Preparing your review',
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppPalette.ink.withValues(alpha: 0.82),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = _controller.value;
          final travel = value <= 0.5 ? value * 2 : (1 - value) * 2;
          final stage = (value * _stages.length).floor().clamp(
            0,
            _stages.length - 1,
          );
          return LayoutBuilder(
            builder: (context, constraints) {
              final beamTop = 18 + (constraints.maxHeight - 36) * travel;
              return Stack(
                children: [
                  Positioned(
                    left: 18,
                    right: 18,
                    top: beamTop,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppPalette.lime,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.lime.withValues(alpha: 0.85),
                            blurRadius: 16,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 66,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              RotationTransition(
                                turns: _controller,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppPalette.lime.withValues(
                                        alpha: 0.75,
                                      ),
                                      width: 2.5,
                                    ),
                                  ),
                                  child: const Align(
                                    alignment: Alignment.topCenter,
                                    child: CircleAvatar(
                                      radius: 4,
                                      backgroundColor: AppPalette.lime,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.document_scanner_rounded,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: Text(
                            _stages[stage],
                            key: ValueKey(stage),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Identity first · nutrition second',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 17,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: AppPalette.mint,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Your photo is not saved',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.analysis,
    required this.portion,
    required this.saving,
    required this.onPortionChanged,
    required this.onAdd,
    required this.onRetake,
  });

  final FoodAnalysis analysis;
  final double portion;
  final bool saving;
  final ValueChanged<double> onPortionChanged;
  final VoidCallback onAdd;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    if (!analysis.isFood) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppPalette.line),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.no_food_rounded,
              size: 42,
              color: AppPalette.coral,
            ),
            const SizedBox(height: 12),
            Text('No clear meal detected', style: context.text.headlineSmall),
            const SizedBox(height: 6),
            const Text(
              'Nothing was added. Retake the photo with the full plate in good light.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppPalette.muted, height: 1.4),
            ),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: onRetake,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retake photo'),
            ),
          ],
        ),
      );
    }

    final scaled = analysis.scaled(portion);
    final confidenceLabel = analysis.confidence >= 0.78
        ? 'High confidence'
        : analysis.confidence >= 0.55
        ? 'Check portions'
        : 'Low confidence';
    final confidenceColor = analysis.confidence >= 0.78
        ? AppPalette.mint
        : analysis.confidence >= 0.55
        ? AppPalette.sun
        : AppPalette.coral;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Review the estimate',
                style: context.text.headlineMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: confidenceColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                confidenceLabel,
                style: TextStyle(
                  color: confidenceColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppPalette.ink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                analysis.mealName,
                style: context.text.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                analysis.items
                    .map((item) => '${item.name} · ${item.quantity}')
                    .join('\n'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.45,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '${scaled.calories}',
                    style: const TextStyle(
                      color: AppPalette.lime,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Text(
                      'kcal',
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          childAspectRatio: 1.2,
          children: [
            _NutrientTile(
              label: 'Protein',
              value: '${scaled.protein.round()} g',
              color: AppPalette.violet,
            ),
            _NutrientTile(
              label: 'Carbs',
              value: '${scaled.carbs.round()} g',
              color: AppPalette.sun,
            ),
            _NutrientTile(
              label: 'Fat',
              value: '${scaled.fat.round()} g',
              color: AppPalette.coral,
            ),
            _NutrientTile(
              label: 'Fibre',
              value: '${scaled.fiber.toStringAsFixed(1)} g',
              color: AppPalette.mint,
            ),
            _NutrientTile(
              label: 'Sugar',
              value: '${scaled.sugar.toStringAsFixed(1)} g',
              color: AppPalette.sun,
            ),
            _NutrientTile(
              label: 'Sodium',
              value: '${scaled.sodiumMg} mg',
              color: AppPalette.violet,
            ),
          ],
        ),
        if (analysis.isPackagedFood) ...[
          const SizedBox(height: 14),
          _NutritionEvidenceCard(analysis: analysis),
        ],
        const SizedBox(height: 18),
        Text('How much did you eat?', style: context.text.titleLarge),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
              .map((value) {
                return value;
              })
              .map(
                (value) => ChoiceChip(
                  label: Text('$value×'),
                  selected: portion == value,
                  onSelected: (_) => onPortionChanged(value),
                  selectedColor: AppPalette.lime,
                  side: const BorderSide(color: AppPalette.line),
                ),
              )
              .toList(),
        ),
        if (analysis.assumptions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E4),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppPalette.sun,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    analysis.assumptions.join(' '),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppPalette.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: saving ? null : onAdd,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            backgroundColor: AppPalette.ink,
            foregroundColor: Colors.white,
          ),
          icon: saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: AppPalette.lime,
                  ),
                )
              : const Icon(Icons.add_circle_rounded, color: AppPalette.lime),
          label: Text(saving ? 'Adding to today…' : 'Confirm and add to today'),
        ),
        const SizedBox(height: 9),
        Text(
          analysis.hasVerifiedOnlineNutrition
              ? 'These values apply to ${analysis.sourceServing}. Confirm the exact flavour and number of servings before adding it.'
              : 'Image-based nutrition is an estimate. Portion confirmation improves tracking; a readable package label or dietitian is best when precision is critical.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            height: 1.4,
            color: AppPalette.muted,
          ),
        ),
      ],
    );
  }
}

class _NutritionEvidenceCard extends StatelessWidget {
  const _NutritionEvidenceCard({required this.analysis});

  final FoodAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final verified = analysis.hasVerifiedOnlineNutrition;
    final isGrounded = analysis.nutritionSource == 'googleSearch';
    final color = verified ? AppPalette.mint : AppPalette.sun;
    final title = verified
        ? isGrounded
              ? 'Verified with live web sources'
              : 'Matched to a live product label'
        : 'No exact online label match';
    final detail = verified
        ? '${analysis.sourceServing} · ${(analysis.sourceMatchConfidence * 100).round()}% identity match'
        : 'Using a visual estimate. Retake the front label in good light or add the exact brand and flavour.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              verified ? Icons.fact_check_rounded : Icons.manage_search_rounded,
              color: color,
              size: 21,
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
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppPalette.muted,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
                if (verified) ...[
                  const SizedBox(height: 7),
                  InkWell(
                    onTap: () => _showNutritionSources(context, analysis),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'See match evidence',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 15),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showNutritionSources(BuildContext context, FoodAnalysis analysis) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppPalette.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        children: [
          Center(
            child: Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: AppPalette.line,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Why these numbers?', style: context.text.headlineMedium),
          const SizedBox(height: 7),
          Text(
            analysis.sourceNote,
            style: const TextStyle(color: AppPalette.muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalette.ink,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant_rounded, color: AppPalette.lime),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis.mealName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        analysis.sourceServing,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(analysis.sourceMatchConfidence * 100).round()}%',
                  style: const TextStyle(
                    color: AppPalette.lime,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
              ],
            ),
          ),
          if (analysis.searchEntryPointHtml.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Search suggestions',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 9),
            _GoogleSearchEntryPoint(html: analysis.searchEntryPointHtml),
          ],
          const SizedBox(height: 20),
          const Text(
            'Sources used',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 9),
          ...analysis.sources.map((source) => _SourceLink(source: source)),
          const SizedBox(height: 12),
          const Text(
            'Product recipes and labels can change by country or flavour. Always compare the serving and package name before logging.',
            style: TextStyle(
              color: AppPalette.muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.source});

  final NutritionSourceRef source;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(source.url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showAppMessage(context, 'That source could not be opened right now.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.open_in_new_rounded,
                  color: AppPalette.mint,
                  size: 20,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    source.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSearchEntryPoint extends StatefulWidget {
  const _GoogleSearchEntryPoint({required this.html});

  final String html;

  @override
  State<_GoogleSearchEntryPoint> createState() =>
      _GoogleSearchEntryPointState();
}

class _GoogleSearchEntryPointState extends State<_GoogleSearchEntryPoint> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppPalette.line),
      ),
      child: WebViewWidget(controller: _controller),
    );
  }
}

class _NutrientTile extends StatelessWidget {
  const _NutrientTile({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          Text(
            label,
            style: const TextStyle(color: AppPalette.muted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppPalette.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppPalette.coral),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
