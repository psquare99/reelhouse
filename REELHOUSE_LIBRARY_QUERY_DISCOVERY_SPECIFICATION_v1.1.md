# REELHOUSE — Library Query & Discovery Specification v1.1

**Status:** Design Specification — Candidate for Freeze  
**Phase:** Post-Phase 1D / Pre-Implementation  
**Current HEAD:** `2a45f71` — `feat: converge canonical TV identities`  
**Implementation Status:** Not started  
**Database Changes Authorized:** None by this document

---

# 1. Purpose

REELHOUSE has established a canonical media identity architecture through Phases 1A–1D.

The application now distinguishes between:

- filesystem/discovery identity,
- canonical media identity,
- provider identity,
- physical media sources,
- source availability,
- metadata identification state.

The next functional layer is a unified mechanism for:

- browsing,
- searching,
- sorting,
- filtering,
- pagination,
- smart library views,
- personal collections,
- discovery.

This specification defines that architecture.

The primary objective is:

> **Every library surface should express what it wants from the library through a common domain-level query model rather than independently implementing retrieval, sorting, filtering, or search logic.**

The specification also establishes a broader **Discovery** concept containing:

1. Personal Collections
2. Smart Views
3. External Discovery

These are related at the product level but remain semantically distinct.

---

# 2. Design Goals

The system SHALL:

1. Provide a UI-independent Library Query Model.
2. Support reusable search, filtering, sorting, and pagination.
3. Keep query semantics independent of database implementation.
4. Prevent UI code from directly constructing SQL.
5. Perform normal local-library operations entirely offline.
6. Preserve Phase 1A–1D canonical identity invariants.
7. Preserve detected/discovery identity as searchable information.
8. Treat physical media availability separately from logical media identity.
9. Support Movies, TV Shows, Seasons, Episodes, and Collections.
10. Support derived Smart Views through reusable queries.
11. Integrate Personal Collections with the query system.
12. Establish an explicit boundary for External Discovery.
13. Permit external discovery results to be intersected with the local library.
14. Never imply that an externally discovered title is owned or playable.
15. Avoid introducing unnecessary database/schema complexity where current scale does not justify it.
16. Remain extensible without requiring screen-specific query implementations.

---

# 3. Non-Goals

This specification does NOT introduce:

- a built-in video player,
- streaming-server functionality,
- transcoding,
- cloud synchronization,
- user accounts,
- multi-user profiles,
- social functionality,
- AI recommendations,
- subtitle downloading,
- automatic filesystem organization,
- filesystem renaming,
- media relocation,
- watch-party functionality.

External discovery is also **not** equivalent to a recommendation engine.

---

# 4. Core Architectural Principles

## 4.1 Query expresses user intent

A query describes **what the user wants**, not how the database should retrieve it.

The intended architecture is:

```text
UI
 ↓
Domain Query
 ↓
Repository
 ↓
Drift / SQLite
```

The UI SHALL NOT contain SQL or database relationship logic.

---

## 4.2 Local-first

Normal library operations SHALL require no network access.

This includes:

- browsing,
- local search,
- sorting,
- filtering,
- collections,
- favorites,
- watchlist,
- watch state,
- availability,
- counts,
- Smart Views.

External providers are relevant only when obtaining or refreshing external information.

---

## 4.3 Canonical identity remains authoritative

Filesystem names remain discovery hints.

For example:

```text
detectedTitle = "HIMYM"
canonicalTitle = "How I Met Your Mother"
tmdbId = 1100
```

The query layer operates primarily against the canonical library entity while preserving relevant detected fields as searchable data.

Search SHALL NOT change identity.

Identification SHALL remain the responsibility of the metadata system.

---

## 4.4 Query logic belongs below presentation

The following SHALL NOT be implemented independently in screens:

```text
sort
filter
availability joins
watch-state filtering
search
pagination
collection membership
```

These belong in the query/repository architecture.

---

# 5. Query Architecture

The architecture consists of:

```text
                         Library / Discovery
                                │
                         Library Query Layer
                                │
          ┌─────────────────────┼─────────────────────┐
          │                     │                     │
       Search                Filters                Sort
          │                     │                     │
          └─────────────────────┼─────────────────────┘
                                │
                           Pagination
                                │
                                ▼
                       Entity Query Contracts
                                │
       ┌────────────┬───────────┼───────────┬────────────┐
       ▼            ▼           ▼           ▼            ▼
     Movie        TV Show     Season      Episode    Collection
       │            │           │           │            │
       └────────────┴───────────┴───────────┴────────────┘
                                │
                         Query Repository
                                │
                           Drift / SQLite
```

The exact class structure is an implementation concern.

The semantic boundaries defined here are architectural requirements.

---

# 6. Entity Query Contracts

REELHOUSE SHALL define separate query contracts for:

```text
MovieQuery
TvShowQuery
SeasonQuery
EpisodeQuery
CollectionQuery
```

These queries SHALL share reusable primitives where appropriate.

They SHALL NOT expose irrelevant fields merely to achieve artificial genericity.

For example, an EpisodeQuery should not expose movie runtime sorting simply because both are queryable entities.

---

# 7. Query Components

A query MAY contain:

```text
SearchSpec?
FilterSpec
SortSpec
PaginationSpec?
Scope/context
```

Not every query needs every component.

For example, a SeasonQuery may naturally be scoped to a specific TV show.

---

# 8. Search Model

Search SHALL be represented independently from filters.

Conceptually:

```text
SearchSpec
├── query
└── mode
```

Initial search modes:

```text
TITLE
ALL
```

---

# 9. Search Semantics

Local search SHALL:

- operate offline,
- be case-insensitive,
- search canonical title information,
- search relevant detected/discovery identity,
- search provider-derived searchable metadata where locally stored,
- remain read-only.

For example:

```text
detectedTitle = "HIMYM"
canonicalTitle = "How I Met Your Mother"
```

Searching for either:

```text
HIMYM
```

or:

```text
How I Met Your Mother
```

should be capable of returning the same logical TV show.

Search SHALL NOT invoke metadata identification.

Search SHALL NOT mutate canonical metadata.

---

# 10. Search Engine — Initial Strategy

The initial query implementation SHALL NOT require SQLite FTS5.

The first implementation should use the existing SQLite/Drift infrastructure with expanded searchable fields, including `detectedTitle`.

FTS5 may be introduced later if real library scale or search-quality requirements justify it.

Therefore:

> **FTS5 is a future optimization, not a Phase 1E prerequisite.**

Introducing FTS5 would require a separate schema/migration decision and is intentionally deferred.

---

# 11. Sorting Model

Sorting SHALL be represented by:

```text
SortSpec
├── field
└── direction
```

with:

```text
SortDirection
├── ASC
└── DESC
```

The query SHALL support multiple sort clauses.

Example:

```text
[
    TITLE ASC,
    YEAR DESC
]
```

The first clause has priority.

Subsequent clauses resolve ties.

---

# 12. Null Sorting Semantics

Missing canonical metadata is valid.

Examples:

```text
title = NULL
year = NULL
releaseDate = NULL
rating = NULL
```

Sort behavior SHALL therefore be deterministic.

Initial rule:

> **NULL values appear last.**

This SHALL remain true for both ascending and descending ordering unless a query explicitly specifies another null policy.

The query model SHOULD therefore support a `NullsOrder` concept even if the first UI does not expose it.

---

# 13. Movie Sorting

Initial supported fields:

```text
TITLE
RELEASE_DATE
YEAR
RATING
RUNTIME
CREATED_AT
UPDATED_AT
WATCH_STATE
```

Additional fields may be added later without redesigning the query architecture.

---

# 14. TV Show Sorting

Initial supported fields:

```text
TITLE
FIRST_AIR_DATE
LAST_AIR_DATE
RATING
CREATED_AT
UPDATED_AT
WATCH_STATE
```

TV watch-state sorting uses **derived show state**, described below.

---

# 15. Season Sorting

Initial primary sorting:

```text
SEASON_NUMBER
```

Default:

```text
SEASON_NUMBER ASC
```

---

# 16. Episode Sorting

Initial supported fields:

```text
SEASON_NUMBER
EPISODE_NUMBER
AIR_DATE
TITLE
CREATED_AT
WATCH_STATE
```

Default:

```text
SEASON_NUMBER ASC
EPISODE_NUMBER ASC
```

Episode ordering SHALL remain deterministic.

---

# 17. Default Ordering

The application SHALL explicitly define default ordering.

| Entity | Default |
|---|---|
| Movies | Title ASC |
| TV Shows | Title ASC |
| Seasons | Season Number ASC |
| Episodes | Season Number ASC → Episode Number ASC |
| Collections | Existing/persistent collection ordering |

The system SHALL NOT depend on SQLite insertion order.

---

# 18. Watch State

REELHOUSE already uses:

```text
UNWATCHED
IN_PROGRESS
WATCHED
```

This SHALL become a formal domain concept:

```text
WatchState
```

Queries SHALL support filtering by one or multiple states.

Example:

```text
watchState IN [
    UNWATCHED,
    IN_PROGRESS
]
```

---

# 19. Movie Watch State

Movie watch state is stored directly on the Movie entity.

The query layer may therefore filter and sort directly using:

```text
movie.watchState
```

---

# 20. Episode Watch State

Episode watch state is stored directly on Episode.

The query layer may therefore filter and sort episodes directly using:

```text
episode.watchState
```

---

# 21. TV Show Watch State

TV Shows do **not** currently store an independent authoritative watch state.

TV show watch state SHALL therefore be treated as **derived state** based on its episodes.

Conceptually:

```text
TvShow
   ↓
known episodes
   ↓
episode watch states
   ↓
derived TvShowWatchState
```

Initial semantic model:

### UNWATCHED

No known episode has been watched or started.

### IN_PROGRESS

At least one known episode is watched/in progress, but the known episode set is not completely watched.

### WATCHED

All known episodes in the relevant local episode set are watched.

### Important limitation

A show SHALL NOT be considered fully watched merely because every currently scanned episode is watched if the application has evidence that the local episode catalogue is incomplete.

The precise handling of incomplete seasons/episode metadata SHALL be finalized during implementation and acceptance testing.

The important architectural rule is:

> **TV show watch state is derived, not an independently stored boolean.**

---

# 22. Continue Watching

Continue Watching SHALL be implemented as a query/view over watch state rather than as an independent database concept.

For movies:

```text
watchState == IN_PROGRESS
sort = UPDATED_AT DESC
```

For episodes:

```text
watchState == IN_PROGRESS
sort = UPDATED_AT DESC
```

The exact ordering may be refined during functional acceptance.

---

# 23. Next Episode

"Next Episode" is **not a basic query primitive**.

It is domain behavior built on top of ordered episode retrieval.

Conceptually:

```text
TvShow
 ↓
ordered episodes
 ↓
first episode that is not WATCHED
 ↓
NextEpisode
```

This should eventually live in a dedicated domain resolver/service rather than becoming a special SQL filter.

---

# 24. Availability Architecture

REELHOUSE currently has richer availability semantics than a simple boolean.

Physical availability depends on:

- MediaSource availability,
- Storage availability,
- source type.

The existing resolver can distinguish:

```text
availableLocally
availableOnRemovableStorage
availableOnMultipleSources
unavailable
```

This richer information SHALL be preserved.

---

# 25. Generic Availability Filter

For library querying, the query model SHALL support a simplified logical availability filter:

```text
AVAILABLE
UNAVAILABLE
```

The meaning is:

### AVAILABLE

At least one valid physical MediaSource can currently be used.

### UNAVAILABLE

No associated physical MediaSource is currently usable.

Thus:

```text
Movie
 ├── E:\Movies\Matrix.mkv      available
 └── F:\Backup\Matrix.mkv      unavailable
```

has:

```text
logical availability = AVAILABLE
```

---

# 26. Availability Detail

The query result MAY additionally expose richer availability information:

```text
AvailabilityDetail
├── availableLocally
├── availableOnRemovableStorage
├── availableOnMultipleSources
└── unavailable
```

This prevents the query system from throwing away information currently used by REELHOUSE's availability resolver.

---

# 27. Availability Query Performance

The query system SHALL avoid the current per-card availability query pattern.

Instead of:

```text
Movie 1 → query sources
Movie 2 → query sources
Movie 3 → query sources
...
```

the repository SHOULD retrieve the necessary availability information through:

- a joined query,
- grouped relational query,
- or efficient batch projection.

The final implementation must eliminate the catalogue-grid N+1 availability subscription pattern.

---

# 28. Catalogue Preservation

Disconnecting a storage device SHALL NOT remove logical library entities.

The query layer SHALL therefore be able to return:

```text
Movie exists
Media unavailable
```

as a valid catalogue result.

This is a core REELHOUSE behavior.

---

# 29. Filter Model

Filters SHALL be composable.

Initial filter dimensions:

```text
WatchState
Favorite
Watchlist
Availability
MetadataStatus
Year/Date
Collection
Storage/Source
```

Genre is intentionally excluded from initial implementation because the current schema does not model genre data.

---

# 30. Favorite Filter

Where supported:

```text
isFavorite == true
```

Favorites remain user state.

They SHALL NOT be represented as ordinary Collections.

---

# 31. Watchlist Filter

Where supported:

```text
isWatchlist == true
```

Watchlist remains distinct from Favorites.

---

# 32. Metadata Status Filter

The existing identity status values SHALL be queryable:

```text
PENDING
IDENTIFIED
NEEDS_VERIFICATION
```

This enables maintenance views such as:

> Needs Verification

The query layer SHALL use the actual identity state rather than inferring it solely from `tmdbId`.

---

# 33. Year / Date Filters

Where supported, queries SHALL permit bounded filtering.

Example:

```text
year >= 2010
year <= 2020
```

or:

```text
releaseDate BETWEEN X AND Y
```

Null metadata SHALL NOT satisfy bounded ranges.

---

# 34. Genre Filtering — Deferred

Genre filtering SHALL NOT be implemented in the initial Library Query milestone.

The current schema does not model genre data.

Before genre filtering can be implemented, REELHOUSE requires a separate metadata/domain decision covering:

- genre representation,
- provider mapping,
- storage structure,
- synchronization behavior,
- query indexing.

Therefore:

> **Genre filtering is a deferred dependency, not a missing query primitive to be hacked into Phase 1E.**

---

# 35. Collection Membership Filter

A MovieQuery or TvShowQuery MAY filter by:

```text
collectionId
```

Existing collection membership remains authoritative.

This allows:

```text
MovieQuery(
    collectionId: X
)
```

rather than creating a bespoke collection retrieval system.

---

# 36. Storage / Source Filter

Library queries SHOULD support administrative filtering by:

```text
storageId
sourceId
```

Examples:

> Movies currently associated with Storage A.

> Media originating from this specific source.

This functionality is primarily intended for library management and maintenance.

---

# 37. Filter Composition

Initial implementation SHALL prioritize predictable `AND` semantics.

Example:

```text
Movies
WHERE
    watchState = UNWATCHED
    AND availability = AVAILABLE
    AND year >= 2010
```

Complex arbitrary boolean expression trees are intentionally deferred.

The query model SHOULD remain extensible enough to support them later if required.

---

# 38. Query Scope

Queries MAY have a contextual scope.

Examples:

```text
All Movies
Collection: Marvel
Favorites
Watchlist
Search Results
Recently Added
TV Show: Friends
Season: 1
```

Scope is a contextual constraint, not necessarily a new database entity.

This allows Discovery and library screens to reuse the same query infrastructure.

---

# 39. Pagination

Pagination SHALL be part of the query contract.

Initial model:

```text
PaginationSpec
├── limit
└── offset
```

The implementation may initially use SQLite `LIMIT/OFFSET`.

The architecture SHALL remain compatible with future cursor/keyset pagination.

---

# 40. Query Result

The query layer SHALL support structured results.

Conceptually:

```text
LibraryResult<T>
├── items
├── totalCount
└── hasMore
```

However, the result item itself may be a **library query projection** rather than a raw database entity.

---

# 41. Library Query Projections

The UI frequently requires information that spans multiple entities.

For example, a Movie card may need:

```text
Movie
+
Availability
+
possibly collection/state information
```

Therefore, the query layer MAY return dedicated read projections such as:

```text
MovieLibraryItem
TvShowLibraryItem
EpisodeLibraryItem
```

rather than forcing the UI to issue additional database queries.

The projection should contain only data required for the relevant library surface.

This is intended to eliminate unnecessary UI-side joins and N+1 queries.

The exact projection classes are an implementation decision.

---

# 42. Reactive vs One-Shot Queries

The repository layer SHALL support both reactive and one-shot access patterns.

### Reactive

Appropriate for:

- catalogue screens,
- availability-sensitive views,
- live library changes.

Conceptually:

```text
Stream<LibraryResult<T>>
```

### One-shot

Appropriate for:

- counts,
- one-time lookups,
- resolvers,
- maintenance operations.

Conceptually:

```text
Future<LibraryResult<T>>
```

The query contract itself SHALL not force every operation into a Stream.

---

# 43. Repository Boundary

The intended architecture is:

```text
Presentation
      ↓
Library Query Contract
      ↓
Repository
      ↓
Database
```

Conceptually:

```text
MovieRepository.query(MovieQuery)
TvShowRepository.query(TvShowQuery)
SeasonRepository.query(SeasonQuery)
EpisodeRepository.query(EpisodeQuery)
CollectionRepository.query(CollectionQuery)
```

The exact interface names may change during implementation.

The boundary itself SHALL remain.

---

# 44. Smart Views

Smart Views are **predefined dynamic queries**.

They are not persistent Collection records.

Examples:

```text
Continue Watching
Recently Added
Recently Watched
Favorites
Watchlist
Unwatched
Available Now
Needs Verification
```

Each should ultimately map to a reusable query definition.

---

# 45. Smart Views Are Not Collections

The database SHALL NOT create fake persistent collections for:

```text
Favorites
Watchlist
Recently Added
Continue Watching
```

unless a future requirement explicitly calls for user-persisted Smart Views.

This avoids polluting the Collections model.

---

# 46. Discovery Architecture

The current "Collections" experience should conceptually evolve into a broader:

# Discovery

Discovery consists of:

```text
Discovery
│
├── Personal Collections
├── Smart Views
└── External Discovery
```

These are intentionally different sources of organization/discovery.

---

# 47. Personal Collections

Personal Collections are:

- persistent,
- user-created,
- user-curated.

Examples:

```text
Marvel
Christopher Nolan
Hindi Classics
Comfort Movies
Weekend Watch
```

A title may belong to multiple collections.

Existing collection membership and display ordering remain valid.

The query system should simply make collections usable as query constraints.

---

# 48. Smart Views

Smart Views are generated from the local library.

Examples:

```text
Continue Watching
Recently Added
Favorites
Watchlist
Unwatched
Available
Needs Verification
```

They do not represent independent catalogue entities.

---

# 49. External Discovery

External Discovery represents data originating outside the user's local catalogue.

Examples:

```text
IMDb Top Rated Movies
IMDb Top Rated TV Shows
Popular Movies
Popular TV Shows
Trending
Genre-specific external lists
```

External Discovery is an exploration mechanism.

It is NOT a second local library.

---

# 50. Canonical Metadata vs External Discovery

REELHOUSE SHALL preserve a strict separation between:

### Canonical metadata

Currently provided primarily through TMDB.

Examples:

- canonical title,
- provider identity,
- release information,
- artwork,
- episode metadata.

### External discovery

Examples:

- rankings,
- popularity,
- external lists,
- external ordering.

An external ranking source SHALL NOT automatically become REELHOUSE's canonical metadata provider.

---

# 51. External Lists

Conceptually:

```text
ExternalList
├── provider
├── list identity
├── title
├── entries
└── retrieval/cache metadata
```

The exact persistence model is deferred to the External Discovery implementation milestone.

---

# 52. External Discovery Must Not Pollute the Local Library

An external list entry SHALL NOT automatically create a Movie or TvShow record.

For example:

```text
IMDb Top Rated Movies
```

must not create hundreds of local library records simply because they appear on the list.

The local library represents the user's media catalogue.

---

# 53. External List / Local Library Intersection

External discovery SHOULD support intersection with the local library.

Conceptually:

```text
External List
      ↓
Provider identities
      ↓
Canonical identity matching
      ↓
Local library
```

This allows:

> IMDb Top Rated Movies — In My Library

without turning IMDb into the local catalogue.

---

# 54. External Identity Matching

Where a stable provider identity exists, matching SHOULD use provider identity rather than title-only matching.

This follows the canonical identity architecture established in Phase 1D.

Title similarity may assist discovery but SHALL NOT silently replace canonical identity.

---

# 55. External Ownership Semantics

An external discovery result must never imply playback capability.

An external title can be conceptually:

```text
EXTERNAL_ONLY
```

or:

```text
IN_LIBRARY_UNAVAILABLE
```

or:

```text
IN_LIBRARY_AVAILABLE
```

Only the latter has a currently playable local source.

The exact implementation representation may be refined later.

The semantic distinction is mandatory.

---

# 56. Discovery Example

A future Discovery surface could conceptually contain:

```text
DISCOVER

Continue Watching
──────────────────

My Collections
──────────────────

Recently Added
──────────────────

Favorites
──────────────────

IMDb Top Rated Movies
──────────────────

IMDb Top Rated TV Shows
──────────────────
```

The final visual design is explicitly deferred to the final UI/UX phase.

---

# 57. Performance Requirements

The query architecture SHALL avoid unnecessary full-library Dart processing.

Where practical, the database should perform:

- filtering,
- sorting,
- searching,
- counting,
- pagination,
- relational availability calculation.

The system SHALL NOT retrieve thousands of rows merely to execute simple filters in Dart.

---

# 58. Cross-Platform Semantics

The domain meaning of queries SHALL remain consistent across:

- Windows,
- Android,
- Web.

Each platform may have different storage availability and separate local databases.

Those platform-specific differences belong below the query/domain boundary.

---

# 59. Deferred Features

The following are deliberately deferred from the first implementation:

### FTS5

Deferred until performance/search-quality testing justifies it.

### Genre

Deferred until metadata genre representation is designed.

### Persisted user-defined Smart Views

Deferred until there is an actual requirement for user-created dynamic queries.

### Cursor pagination

Deferred until library scale requires it.

### Complex boolean filter expressions

Deferred until actual use cases justify them.

### External Discovery providers

The abstraction belongs in this specification, but concrete provider integrations are a separate milestone.

---

# 60. Acceptance Criteria

## Query Foundation

- [ ] Domain query contracts exist for Movies.
- [ ] Domain query contracts exist for TV Shows.
- [ ] Domain query contracts exist for Seasons.
- [ ] Domain query contracts exist for Episodes.
- [ ] Domain query contracts exist for Collections.
- [ ] Queries are UI-independent.
- [ ] Queries do not expose SQL implementation details.

## Search

- [ ] Local search works offline.
- [ ] Canonical titles are searchable.
- [ ] Detected titles remain searchable.
- [ ] Search does not mutate metadata.
- [ ] Search is reusable across library surfaces.

## Sorting

- [ ] Movie sorting supports defined fields.
- [ ] TV sorting supports defined fields.
- [ ] Episode sorting supports defined fields.
- [ ] Multiple sort clauses are supported.
- [ ] Null values are deterministic and default to last.
- [ ] Default ordering is explicitly defined.

## Filtering

- [ ] Watch-state filters work.
- [ ] Favorite filters work.
- [ ] Watchlist filters work.
- [ ] Availability filters work.
- [ ] Metadata-state filters work.
- [ ] Year/date filters work where applicable.
- [ ] Collection membership filters work.
- [ ] Storage/source filtering works where applicable.
- [ ] Genre is not implemented until its metadata model exists.

## Availability

- [ ] Logical media remains visible when storage disconnects.
- [ ] Logical availability accounts for multiple physical sources.
- [ ] Generic AVAILABLE/UNAVAILABLE filtering works.
- [ ] Rich availability information can remain available to presentation.
- [ ] Catalogue grids do not use per-card N+1 availability queries.

## Watch State

- [ ] Movie watch state can be queried.
- [ ] Episode watch state can be queried.
- [ ] TV show watch state is derived rather than independently stored.
- [ ] Continue Watching can be represented as a query.
- [ ] Next Episode remains a domain resolver rather than a query primitive.

## Collections

- [ ] Personal collections remain persistent.
- [ ] Collection membership can constrain library queries.
- [ ] Favorites and Watchlist remain distinct from Collections.
- [ ] Collection ordering remains preserved.

## Smart Views

- [ ] Smart Views are reusable query definitions.
- [ ] Smart Views do not create fake collection entities.
- [ ] Continue Watching exists as a Smart View.
- [ ] Recently Added exists as a Smart View.
- [ ] Favorites exists as a Smart View.
- [ ] Watchlist exists as a Smart View.
- [ ] Unwatched exists as a Smart View.
- [ ] Needs Verification exists as a Smart View.

## Discovery

- [ ] Discovery distinguishes Personal Collections.
- [ ] Discovery distinguishes Smart Views.
- [ ] Discovery distinguishes External Discovery.
- [ ] External discovery does not create local library records automatically.
- [ ] External entries can be intersected with the local library.
- [ ] External entries never imply ownership or playback availability.

## Architecture

- [ ] UI contains no direct SQL.
- [ ] Query logic is centralized.
- [ ] Database implementation remains behind repositories.
- [ ] Query semantics work offline.
- [ ] Existing Phase 1A–1D invariants remain intact.
- [ ] Existing test suite remains passing.

---

# 61. Proposed Implementation Roadmap

The implementation SHALL be divided into bounded milestones.

## Phase 1E.1 — Query Domain Contracts

Design/implement only the domain contracts:

```text
SearchSpec
SortSpec
SortField
SortDirection
NullsOrder
Filter definitions
PaginationSpec
LibraryResult
Library query projections
MovieQuery
TvShowQuery
SeasonQuery
EpisodeQuery
CollectionQuery
```

No major database refactoring.

No UI redesign.

---

## Phase 1E.2 — Database Query Engine

Implement repository/data-layer translation:

- SQL/Drift query construction,
- server-side filtering,
- server-side sorting,
- pagination,
- relational availability projection,
- efficient collection membership,
- query tests.

Eliminate the need for UI-side filtering.

---

## Phase 1E.3 — Repository & Reactive Integration

Introduce the repository/query service boundary.

Migrate:

- Movies catalogue,
- TV catalogue,
- Home sections,
- Offline library,
- Collections.

Support reactive and one-shot query consumers.

---

## Phase 1E.4 — Search Enhancement

Improve local search to include detected identity fields.

Evaluate search performance against the real library.

Only introduce FTS5 if actual requirements justify it.

---

## Phase 1E.5 — Smart Views & Discovery

Implement:

- Continue Watching,
- Recently Added,
- Favorites,
- Watchlist,
- Unwatched,
- Available,
- Needs Verification,
- Discovery surface,
- Personal Collections integration.

---

## Phase 1E.6 — External Discovery

Separate milestone for:

- ExternalList abstraction,
- provider integration,
- caching,
- provider identity matching,
- local-library intersection.

Concrete providers such as IMDb should be treated as integrations, not as part of the local library architecture.

---

# 62. Final Architectural Boundary

The resulting REELHOUSE architecture should conceptually look like:

```text
                         REELHOUSE
                            │
                     ┌──────┴──────┐
                     │             │
                  LIBRARY       DISCOVERY
                     │             │
                     │       ┌─────┼─────┐
                     │       │     │     │
                     │    Personal Smart External
                     │ Collections Views Discovery
                     │       │     │     │
                     └───────┼─────┼─────┘
                             │
                       Library Query
                             │
              ┌──────────────┼──────────────┐
              │              │              │
           Search         Filters          Sort
              │              │              │
              └──────────────┼──────────────┘
                             │
                        Pagination
                             │
                             ▼
                       Query Projections
                             │
                    ┌────────┼────────┐
                    │        │        │
                  Movie    TV Show  Episode
                    │        │        │
                    └────────┼────────┘
                             ▼
                        Repository
                             │
                         Drift/SQLite
```

Alongside this remain the existing specialized domain systems:

```text
LibraryScanner
      ↓
Filesystem discovery

MetadataService
      ↓
Canonical metadata / identity

AvailabilityResolver
      ↓
Physical availability

PlaybackSourceResolver
      ↓
Playable MediaSource

PlaybackLauncher
      ↓
External player
```

These responsibilities SHALL remain separate.

---

# 63. Architectural Decision

The following decisions are proposed for **v1.1 freeze**:

### Decision 1

> REELHOUSE will use a domain-level Library Query Model as the semantic interface for local library retrieval.

### Decision 2

> Sorting, filtering, search, availability querying, pagination, and Smart Views will use the Library Query architecture rather than screen-specific implementations.

### Decision 3

> Library query results may use dedicated read projections so presentation surfaces do not require additional N+1 database queries.

### Decision 4

> TV Show watch state is derived from episode state and is not introduced as an independently authoritative stored field.

### Decision 5

> Logical availability is binary for generic filtering, while the existing richer availability resolver semantics remain available for presentation.

### Decision 6

> FTS5 is deferred until actual performance/search-quality requirements justify its introduction.

### Decision 7

> Genre filtering is deferred until genre metadata has a defined domain/database representation.

### Decision 8

> Smart Views are code-defined query presets initially and are not persisted as ordinary Collections.

### Decision 9

> The Collections surface evolves conceptually into Discovery, containing Personal Collections, Smart Views, and External Discovery.

### Decision 10

> External Discovery remains separate from the local library and canonical metadata. External list entries do not imply ownership, availability, or playability.

### Decision 11

> TMDB remains the current canonical metadata/identity provider; external ranking/list providers such as IMDb are discovery sources rather than replacements for canonical metadata.

---

# 64. Freeze Condition

This specification should be considered **ready for implementation once the above architectural decisions are accepted**.

No database migration, UI refactor, or implementation work is authorized merely by accepting this document.

The next implementation checkpoint should be:

> **Phase 1E.1 — Query Domain Contracts**

with the narrowly bounded objective of implementing the domain-level contracts defined above, followed by tests, analysis, and a clean commit.
