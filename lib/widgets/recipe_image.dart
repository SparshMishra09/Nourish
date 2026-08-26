import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/recipe.dart';

class RecipeImage extends StatelessWidget {
  const RecipeImage({
    super.key,
    required this.recipe,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final Recipe recipe;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFFBD0), Color(0xFFD9F7EE)],
        ),
      ),
      child: Text(recipe.emoji, style: const TextStyle(fontSize: 48)),
    );

    final Widget image;
    if (recipe.imageAsset.isNotEmpty) {
      image = Image.asset(
        recipe.imageAsset,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => fallback(),
      );
    } else if (recipe.imageUrl.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: recipe.imageUrl,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        fadeInDuration: const Duration(milliseconds: 180),
        placeholder: (_, _) => Container(
          width: width,
          height: height,
          color: AppPalette.line,
          alignment: Alignment.center,
          child: const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, _, _) => fallback(),
      );
    } else {
      image = fallback();
    }

    return Semantics(
      image: true,
      label: 'Photo of ${recipe.name}',
      child: ExcludeSemantics(child: image),
    );
  }
}
