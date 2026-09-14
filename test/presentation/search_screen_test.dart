import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reelhouse/core/theme/cinema_theme.dart';
import 'package:reelhouse/data/database/database.dart';
import 'package:reelhouse/presentation/search/search_screen.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('SearchScreen searches movies and TV shows instantly', (
    tester,
  ) async {
    final now = DateTime.now();

    await db
        .into(db.movies)
        .insert(
          MoviesCompanion.insert(
            id: 'm-blade-runner',
            title: 'Blade Runner 2049',
            year: const drift.Value(2017),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.tvShows)
        .insert(
          TvShowsCompanion.insert(
            id: 'tv-westworld',
            title: 'Westworld',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.darkTheme,
        home: SearchScreen(database: db),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Fast Local Cinema Search'), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField), 'Blade');
    await tester.pumpAndSettle();

    expect(find.text('MOVIES (1)'), findsOneWidget);
    expect(find.text('Blade Runner 2049'), findsOneWidget);

    // Clear search
    final clearButton = find.byIcon(Icons.clear);
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(find.text('Fast Local Cinema Search'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
