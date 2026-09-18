import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/domain/models/genre_definition.dart';

void main() {
  group('GenreResolver', () {
    test('resolves composite Action & Adventure to constituent and combined values', () {
      final matching = GenreResolver.resolveMatchingValues(
        'Action & Adventure',
      );
      expect(
        matching,
        containsAll(['Action', 'Adventure', 'Action & Adventure']),
      );
    });

    test(
      'resolves composite Sci-Fi & Fantasy to constituent and combined values',
      () {
        final matching = GenreResolver.resolveMatchingValues(
          'Sci-Fi & Fantasy',
        );
        expect(
          matching,
          containsAll(['Science Fiction', 'Fantasy', 'Sci-Fi & Fantasy']),
        );
      },
    );

    test(
      'resolves composite War & Politics to constituent and combined values',
      () {
        final matching = GenreResolver.resolveMatchingValues('War & Politics');
        expect(matching, containsAll(['War', 'Politics', 'War & Politics']));
      },
    );

    test(
      'preserves ordinary Action genre without absorbing Adventure or Fantasy',
      () {
        final matching = GenreResolver.resolveMatchingValues('Action');
        expect(matching, equals(['Action']));
        expect(matching, isNot(contains('Adventure')));
        expect(matching, isNot(contains('Fantasy')));
      },
    );

    test('preserves ordinary Adventure genre without absorbing Action', () {
      final matching = GenreResolver.resolveMatchingValues('Adventure');
      expect(matching, equals(['Adventure']));
      expect(matching, isNot(contains('Action')));
    });

    test(
      'preserves ordinary Fantasy genre without absorbing Science Fiction',
      () {
        final matching = GenreResolver.resolveMatchingValues('Fantasy');
        expect(matching, equals(['Fantasy']));
        expect(matching, isNot(contains('Science Fiction')));
      },
    );

    test(
      'preserves ordinary Science Fiction genre without absorbing Fantasy',
      () {
        final matching = GenreResolver.resolveMatchingValues('Science Fiction');
        expect(matching, containsAll(['Science Fiction', 'Sci-Fi']));
        expect(matching, isNot(contains('Fantasy')));
      },
    );

    test('canonicalizes casing and spacing for discovered genres', () {
      expect(
        GenreResolver.canonicalize('sci-fi & fantasy'),
        equals('Sci-Fi & Fantasy'),
      );
      expect(
        GenreResolver.canonicalize('action & adventure'),
        equals('Action & Adventure'),
      );
      expect(
        GenreResolver.canonicalize('science fiction'),
        equals('Science Fiction'),
      );
      expect(GenreResolver.canonicalize('Comedy'), equals('Comedy'));
    });
  });
}
