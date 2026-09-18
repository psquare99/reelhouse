/// Canonical genre definition mapping a conceptual discovery genre to its underlying
/// provider and storage representations across Movies and TV Shows.
class GenreDefinition {
  /// The canonical display name of the genre (e.g. "Action & Adventure", "Sci-Fi & Fantasy").
  final String displayName;

  /// The list of stored genre strings that satisfy this conceptual category.
  final List<String> matchingValues;

  const GenreDefinition({
    required this.displayName,
    required this.matchingValues,
  });
}

/// Domain resolver for canonical genre resolution and cross-media matching.
class GenreResolver {
  /// Known composite and canonical genre definitions.
  static const List<GenreDefinition> definitions = [
    GenreDefinition(
      displayName: 'Action & Adventure',
      matchingValues: ['Action & Adventure', 'Action', 'Adventure'],
    ),
    GenreDefinition(
      displayName: 'Sci-Fi & Fantasy',
      matchingValues: [
        'Sci-Fi & Fantasy',
        'Science Fiction',
        'Fantasy',
        'Sci-Fi',
        'Science-Fiction',
      ],
    ),
    GenreDefinition(
      displayName: 'War & Politics',
      matchingValues: ['War & Politics', 'War', 'Politics'],
    ),
    GenreDefinition(
      displayName: 'Science Fiction',
      matchingValues: ['Science Fiction', 'Sci-Fi', 'Science-Fiction'],
    ),
  ];

  /// Resolves a requested display or filter genre into all matching database genre values.
  ///
  /// For composite categories (e.g. "Action & Adventure", "Sci-Fi & Fantasy"), returns all
  /// constituent provider representations across Movies and TV.
  /// For ordinary categories (e.g. "Action", "Fantasy"), returns only that specific genre
  /// and its direct spelling variants without absorbing unrelated constituent genres.
  static List<String> resolveMatchingValues(String genre) {
    final trimmed = genre.trim();
    if (trimmed.isEmpty) return const [];

    final normalized = trimmed.toLowerCase();

    for (final def in definitions) {
      if (def.displayName.toLowerCase() == normalized) {
        return def.matchingValues;
      }
    }

    return [trimmed];
  }

  /// Canonicalizes a raw discovered genre name for consistent display and cataloguing.
  static String canonicalize(String rawGenre) {
    final trimmed = rawGenre.trim();
    if (trimmed.isEmpty) return '';

    final normalized = trimmed.toLowerCase();
    for (final def in definitions) {
      if (def.displayName.toLowerCase() == normalized) {
        return def.displayName;
      }
      for (final matchVal in def.matchingValues) {
        if (matchVal.toLowerCase() == normalized &&
            def.matchingValues.length == 1) {
          return def.displayName;
        }
      }
    }

    return trimmed;
  }
}
