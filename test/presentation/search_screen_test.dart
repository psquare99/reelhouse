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
            detectedTitle: 'Blade Runner 2049',
            title: const drift.Value('Blade Runner 2049'),
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
            detectedTitle: 'Westworld',
            title: const drift.Value('Westworld'),
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

  testWidgets('SearchScreen text styles adapt properly in Light Mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CinemaTheme.lightTheme,
        home: SearchScreen(database: db),
      ),
    );

    await tester.pumpAndSettle();

    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);
    final textField = tester.widget<TextField>(textFieldFinder);

    // Verify text color is dark/readable in light mode
    expect(textField.style?.color, isNotNull);
    expect(textField.style!.color!.computeLuminance(), lessThan(0.5));

    await tester.enterText(textFieldFinder, 'Testing Light Mode Query');
    await tester.pumpAndSettle();

    expect(find.text('Testing Light Mode Query'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
