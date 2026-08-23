import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
              'Nourish could not read this photo. Retake it with the app camera and try again. [PHOTO]',
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
                  'Take a clear, top-down photo of the full plate. Confirm the portion before it counts toward today.',
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
                  hintText: 'e.g. homemade paneer curry, 2 rotis',
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
                      ? 'Analyzing the full plate…'
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
    required this.onCamera,
    required this.onGallery,
  });

  final XFile? image;
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
                    'Keep the whole plate in frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Good light · top-down · no blur',
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
        const Text(
          'Image-based nutrition is an estimate. Portion confirmation improves tracking; labels or a dietitian are best when precision is critical.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            height: 1.4,
            color: AppPalette.muted,
          ),
        ),
      ],
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
