import '../models/recipe.dart';

/// Combines Nourish's complete offline catalog with optional cloud updates.
///
/// A matching cloud recipe may update any populated field. Missing fields are
/// restored from the bundled recipe, so an old or partially edited Firebase
/// document can never remove a photo, ingredient list, allergen warning, or
/// cooking method from the app. New cloud-only recipes are accepted only when
/// they pass the same completeness rules as bundled recipes.
class RecipeCatalog {
  const RecipeCatalog._();

  static List<Recipe> merge({
    required List<Recipe> bundled,
    required List<Recipe> remote,
  }) {
    final remoteById = {for (final recipe in remote) recipe.id: recipe};
    final bundledIds = bundled.map((recipe) => recipe.id).toSet();

    final merged = bundled
        .map(
          (fallback) =>
              remoteById[fallback.id]?.mergeWithFallback(fallback) ?? fallback,
        )
        .toList();
    merged.addAll(
      remote.where(
        (recipe) => !bundledIds.contains(recipe.id) && recipe.isComplete,
      ),
    );
    return merged;
  }
}
