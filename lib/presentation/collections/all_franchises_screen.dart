import 'package:flutter/material.dart';

import '../../core/theme/cinema_theme.dart';
import '../../data/database/database.dart';
import '../../domain/query/query_projections.dart';
import '../../domain/repository/library_repository.dart';
import '../widgets/cinema_error_state.dart';
import '../widgets/cinema_loading_skeleton.dart';
import '../widgets/cinema_poster_card.dart';
import 'system_curation_grid_screen.dart';

/// Screen presenting the complete catalogue of all movie franchises / sagas
/// discovered in the local library.
class AllFranchisesScreen extends StatelessWidget {
  final LibraryRepository repository;
  final AppDatabase? database;

  const AllFranchisesScreen({
    super.key,
    required this.repository,
    this.database,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = CinemaTheme.of(context);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(title: const Text('Franchises')),
      body: StreamBuilder<List<FranchiseLibraryItem>>(
        stream: repository.watchFranchises(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return CinemaErrorState(
              title: 'Unable to Load Franchises',
              message: snapshot.error.toString(),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: CinemaGridSkeleton(),
            );
          }

          final franchises = snapshot.data ?? [];
          if (franchises.isEmpty) {
            return Center(
              child: Text(
                'No franchises found in library.',
                style: TextStyle(color: tokens.textMuted, fontSize: 14),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1200
                  ? 6
                  : width > 900
                  ? 5
                  : width > 600
                  ? 4
                  : 3;

              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                ),
                itemCount: franchises.length,
                itemBuilder: (context, index) {
                  final franchise = franchises[index];
                  return CinemaPosterCard(
                    title: franchise.name,
                    subtitle:
                        '${franchise.movieCount} ${franchise.movieCount == 1 ? 'Film' : 'Films'}',
                    posterPath: franchise.posterPath,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SystemCurationGridScreen(
                            title: franchise.name,
                            tmdbCollectionId: franchise.id,
                            tmdbCollectionName: franchise.name,
                            repository: repository,
                            database: database,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
