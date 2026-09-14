# REELHOUSE
## Personal Digital Cinema
### Implementation Design Document — v1.0

---

## 1. Executive Summary

**REELHOUSE** is a personal digital cinema application for organizing and presenting an existing collection of movies and TV shows stored on local disks.

REELHOUSE is **not a media player, media server, file manager, or Plex/Jellyfin clone**.

Its purpose is simple:

> Turn a collection of locally stored media files into a beautiful, persistent, searchable personal cinema.

The physical media remains wherever the user has stored it. REELHOUSE creates a local library database containing the identity, metadata, state, and location of those media files.

The application must continue to display the user's catalogue even when the physical disks containing the media are disconnected.

The initial release targets:

- Desktop
- Android
- Web

Each platform operates independently and maintains its own local library database.

---

# 2. Product Principles

These principles are mandatory and should guide implementation decisions.

### 2.1 The library is permanent; disks are sources

A disconnected disk does not mean its movies disappear from the library.

The application remembers them and marks them unavailable.

### 2.2 Local first

The application must work primarily from locally stored library data.

Browsing the existing catalogue must not require an internet connection.

### 2.3 The user's folders are none of our business

REELHOUSE must never require users to reorganize, rename, or restructure their media folders.

It indexes existing organization.

Example:

```text
Movies/
    Die Hard/
        Die Hard.mkv
        Die Hard 2.mkv
        Die Hard with a Vengeance.mkv
```

This is perfectly valid.

REELHOUSE builds a logical catalogue on top of it.

### 2.4 Dynamic means state-aware

The interface should represent the actual current state of the library.

It should not bombard the user with automatically generated recommendations, statistics, or unnecessary information.

Example:

If a movie is available:

> **PLAY**

If its disk is disconnected:

> **CONNECT DISK**

The application should always communicate what the user can actually do.

### 2.5 Metadata should be fetched once and retained

External metadata should be cached locally.

Opening REELHOUSE should not require repeatedly fetching movie information.

### 2.6 The application should feel designed

The UI must not resemble a generic AI-generated CRUD application.

Avoid:

- generic dashboards
- excessive cards
- unnecessary gradients
- meaningless glassmorphism
- dense tables
- excessive badges
- generic SaaS layouts
- feature clutter

REELHOUSE should feel like a **personal cinema**.

### 2.7 Media location is separate from media identity

REELHOUSE strictly distinguishes between:

1. The logical media item in the user's cinema.
2. The physical copies/locations of that media.

A movie, TV episode, or other media item may have:

- an original copy on removable storage
- a device-local offline copy
- multiple original copies on different storage devices
- multiple local/device copies in the future

The logical media entity remains completely independent of all physical copies.

Example:

```text
Interstellar
│
├── Original Media
│   └── Movies HDD
│       └── D:\Movies\Interstellar.mkv
│
└── Local Offline Copy
    └── Android Tablet / Local PC
        └── REELHOUSE local storage
```

---

# 3. v1.0 Scope

## Included

### Library

- Add library locations
- Scan media
- Detect movies
- Detect TV shows
- Detect seasons and episodes
- Persistent local database
- Incremental scanning
- Disk availability tracking
- Missing/disconnected media state
- Device-local offline copies ("Download to Device")
- Multi-copy tracking per logical media item
- Offline copy management and device storage reclamation

### Metadata

- Automatic media identification
- Movie metadata
- TV metadata
- Posters
- Backdrops
- Synopsis
- Genres
- Release date/year
- Runtime
- Cast
- Directors/creators
- Ratings
- External IDs
- Cached metadata

### User experience

- Home
- Movies
- TV Shows
- Search
- Movie details
- TV-show details
- Season/episode browsing
- Favorites
- Watchlist
- Watched state
- Continue Watching
- Recently Added
- Collections
- Settings

### Playback

- No internal player
- Preferred media player configuration
- Open media using the platform's available player

### Platforms

- Desktop
- Android
- Web

---

# 4. Explicit v1.0 Non-Goals

Do NOT implement:

- Built-in video player
- Video transcoding
- Media streaming server
- Remote streaming
- Torrent functionality
- Download manager
- Subtitle downloading ecosystem
- Media conversion
- Complex parental-control system
- Social features
- Public sharing
- User accounts/cloud authentication
- Recommendation engine
- AI recommendation system
- Automatic folder reorganization
- Automatic file renaming
- Plex-style server infrastructure

Keep v1.0 focused.

---

# 5. Architecture

REELHOUSE uses a **local-library architecture**.

There is no mandatory central server.

Each platform maintains its own local database.

```text
                    REELHOUSE

        ┌───────────────────────────────┐
        │         Desktop App           │
        │                               │
        │  Local DB + Metadata + State  │
        │              │                │
        │         Local disks            │
        └───────────────────────────────┘


        ┌───────────────────────────────┐
        │         Android App           │
        │                               │
        │  Local DB + Metadata + State  │
        │              │                │
        │        Android storage        │
        └───────────────────────────────┘


        ┌───────────────────────────────┐
        │           Web App             │
        │                               │
        │  Local/Browser Library State  │
        └───────────────────────────────┘
```

The platforms are independent.

A future optional synchronization mechanism may allow the user to synchronize library databases through Google Drive or another storage provider.

This synchronization is **not required for v1.0** and must not become a dependency.

---

# 6. Recommended Technology

Use a cross-platform architecture wherever practical.

### Client

**Flutter**

Reason:

- Android support
- Desktop support
- Mature local database ecosystem
- Shared UI and domain logic
- Good control over custom visual design

### Web

Use Flutter Web if the shared codebase remains practical.

However, web-specific constraints must be respected.

The web client should initially prioritize:

- Catalogue browsing
- Search
- Metadata
- Collections
- Watch state

Local physical media access on browsers should not be assumed.

### Local database

Use a robust embedded database suitable for Flutter, preferably **Drift + SQLite**.

Reason:

- relational data model suits movies/shows/episodes/files
- queries are important
- local-first operation
- reliable migrations
- good Flutter integration

### Metadata

Primary provider:

**TMDB**

Use TMDB for:

- movie identification
- TV identification
- people
- posters
- backdrops
- genres
- synopsis
- release information
- episode information
- external identifiers

Cache all fetched metadata locally.

The application must comply with TMDB API and attribution requirements.

Do not make IMDb the application's primary metadata provider.

Where IMDb identifiers/ratings are available through legitimate supported data, they may be represented separately.

---

# 7. Core Data Model

The implementation should conceptually separate **works** from **physical files**.

## Movie

```text
Movie
- id
- metadataId
- title
- originalTitle
- year
- overview
- runtime
- releaseDate
- posterPath
- backdropPath
- rating
- voteCount
- imdbId
- tmdbId
- createdAt
- updatedAt
```

## TV Show

```text
TvShow
- id
- metadataId
- title
- originalTitle
- overview
- firstAirDate
- posterPath
- backdropPath
- rating
- tmdbId
- imdbId
- createdAt
- updatedAt
```

## Season

```text
Season
- id
- showId
- seasonNumber
- name
- overview
- posterPath
- airDate
- tmdbId
```

## Episode

```text
Episode
- id
- seasonId
- episodeNumber
- name
- overview
- airDate
- runtime
- stillPath
- rating
- tmdbId
```

## Media File

A media file represents a specific physical copy of a movie or episode.

```text
MediaFile
- id
- movieId OR episodeId
- storageId
- relativePath
- filename
- extension
- fileSize
- duration
- videoCodec
- audioCodec
- resolution
- audioChannels
- subtitleInformation
- fingerprint
- copyType (ORIGINAL | DEVICE_LOCAL)
- firstSeenAt
- lastSeenAt
- available
```

A logical Movie or Episode can therefore have multiple physical MediaFiles simultaneously (e.g. one on an external HDD and another as a device-local offline copy).

---

# 8. Storage Model

Every registered storage location gets a persistent identity.

```text
Storage
- id
- name
- storageType (REMOVABLE_VOLUME | DEVICE_LOCAL_STORAGE | NETWORK_SHARE)
- filesystemIdentifier (Volume Serial / GUID / UUID)
- rootPath
- lastSeenAt
- available
```

Each device automatically maintains a built-in `DEVICE_LOCAL_STORAGE` entry pointing to REELHOUSE's secure local app storage. Removable disks (such as external USB hard drives or SD cards) are tracked with their native platform filesystem identifiers.

Example:

```text
Storage (External):
    id: abc123
    name: Movies HDD
    storageType: REMOVABLE_VOLUME
    filesystemIdentifier: 0x5484AB12
    rootPath: D:\Movies

Storage (Device Local):
    id: local-internal
    name: This Device
    storageType: DEVICE_LOCAL_STORAGE
    filesystemIdentifier: internal-app-storage
    rootPath: C:\Users\...\AppData\Local\reelhouse\offline_media
```
```

The filesystem identifier should be used where the platform provides a stable identifier.

Do not rely solely on drive letters.

For example:

```text
D:
```

can change.

The physical storage identity should remain recognizable when possible.

---

# 9. Storage Availability

A storage device has one of two primary states:

```text
AVAILABLE
UNAVAILABLE
```

A MediaFile inherits availability from the storage on which it resides, unless a more specific filesystem check establishes otherwise.

When a disk is disconnected:

```text
Movie
  ↓
MediaFile
  ↓
Storage unavailable
  ↓
Movie remains in library
```

The movie is **not deleted**.

---

# 10. Scanner

The scanner is responsible for discovering media.

User workflow:

```text
Settings
   ↓
Library Locations
   ↓
Add Location
   ↓
Select folder
   ↓
Scan
```

The scanner should recursively inspect files.

It should recognize common media formats such as:

- MKV
- MP4
- AVI
- MOV
- M4V
- WEBM

The supported format list should be extensible.

---

# 11. Incremental Scanning

Scanning must not rebuild the entire library from scratch every time.

First scan:

```text
Discover
→ Parse
→ Identify
→ Metadata
→ Store
```

Later scan:

```text
Discover
→ Compare with existing records
→ Process only new/changed files
→ Mark disappeared files appropriately
```

Existing metadata must not be unnecessarily re-downloaded.

---

# 12. File Identification

The scanner should extract useful information from filenames.

Example:

```text
Interstellar.2014.1080p.BluRay.x265.mkv
```

should produce approximately:

```text
Candidate title: Interstellar
Year: 2014
Resolution: 1080p
Codec: HEVC
```

The scanner should recognize common movie and TV naming conventions.

For TV:

```text
Breaking.Bad.S02E03.1080p.WEB-DL.mkv
```

should produce:

```text
Show: Breaking Bad
Season: 2
Episode: 3
```

Do not expose the raw filename as the primary display title when metadata identification succeeds.

---

# 13. Metadata Identification Pipeline

```text
File discovered
       ↓
Filename parser
       ↓
Candidate title/year/season/episode
       ↓
TMDB search
       ↓
Candidate results
       ↓
Confidence evaluation
       ↓
┌───────────────┐
│ High confidence│
└───────┬───────┘
        ↓
Automatic match
```

For uncertain cases:

```text
Low confidence
      ↓
Manual verification
      ↓
User selects correct title
      ↓
Association saved
```

The manual association must be persistent.

The application should not ask the same question again during every scan.

---

# 14. Manual Verification

When identification fails, present a clean interface:

> **We couldn't confidently identify this media.**

Display:

- filename
- folder
- detected information
- search field
- candidate results

Example:

```text
The Thing.mkv

Possible matches:

The Thing — 1982
The Thing — 2011
The Thing from Another World — 1951
```

User selects the correct result.

The mapping is stored locally.

---

# 15. Metadata Cache

Every metadata object retrieved from TMDB should be cached.

The application should avoid unnecessary repeated API requests.

Cache:

- text metadata
- IDs
- poster references
- backdrop references
- people
- season/episode information

Image caching should be handled separately from relational metadata but remain locally available for normal browsing.

---

# 16. Home Screen

The Home screen is the heart of REELHOUSE.

It should feel like entering a **private cinema**.

It should not look like an administration dashboard.

The Home screen may contain:

### Continue Watching

Only when relevant.

### Recently Added

Media recently added to the library.

### Favorites

Only if the user has favorites.

### Watchlist

Only if the user has watchlist entries.

### Movies

Entry point into the movie catalogue.

### TV Shows

Entry point into the TV catalogue.

The sections should be **state-aware**.

Do not fill the page with artificial sections simply because they exist in the specification.

If the user has no favorites, don't display an empty Favorites section unless an intentional empty state is useful.

---

# 17. Movie Catalogue

Primary visual representation:

**poster-first cinema grid**

Each item should show:

- poster
- title
- year where useful
- availability/play state

Do not overload cards with:

- ratings
- codec information
- file sizes
- excessive badges
- long descriptions

Information belongs on the detail page.

---

# 18. Availability-Aware Cards

This is a defining feature of REELHOUSE.

### Available (Removable Storage Connected)

```text
[Poster]

Interstellar
2014

▶ Play
```

### Available (Device-Local Offline Copy Present)

```text
[Poster]

Interstellar
2014

▶ Play (On Device)
```

Even when external hard drives are completely disconnected, media with a local offline copy remains playable!

### Unavailable (Storage Disconnected, No Local Copy)

```text
[Poster]

Interstellar
2014

Connect Movies HDD
```

Do not show a misleading Play button when the physical media cannot currently be opened.

The unavailable state should be subtle and visually clear.

---

# 19. Movie Detail

The detail page should be cinematic.

Recommended structure:

```text
BACKDROP

Poster

Interstellar
2014 · 2h 49m

★ Rating

Overview...

[ PLAY ]
[ ⬇ DOWNLOAD TO DEVICE ]
[ + WATCHLIST ]
[ ♥ FAVORITE ]

Cast
...

Genres
...

YOUR COPIES

● Movies HDD (Original)
  D:\Movies\Interstellar (2014)\Interstellar.mkv
  14.2 GB · 1080p · HEVC · 5.1
  Status: Connected

○ On This Device (Offline Copy)
  REELHOUSE Local Storage
  14.2 GB · Ready to watch offline
  [ DELETE LOCAL COPY ]
```

If the original HDD is disconnected but a local offline copy exists:

```text
YOUR COPIES

○ Movies HDD (Original)
  Currently disconnected

● On This Device (Offline Copy)
  14.2 GB · Available
  [ PLAY ]  [ DELETE LOCAL COPY ]
```

If all copies are unavailable:

```text
YOUR COPIES

○ Movies HDD (Original)
  Currently unavailable

[ CONNECT DISK ]
```

The metadata, watchlist, favorite, and watch state remain fully visible and interactable regardless of disk availability.

---

# 20. TV Show Experience

TV shows should be represented as a hierarchy.

```text
TV Show
   ↓
Seasons
   ↓
Episodes
   ↓
Media files
```

Show page:

```text
Breaking Bad

5 Seasons · 62 Episodes

Overview...

Cast...

Season 1
Season 2
Season 3
...
```

Episode page/state should show:

- episode title
- episode number
- overview
- air date
- rating
- availability (Available on Disk / Available on Device / Disconnected)
- Play / Connect Disk
- Download to Device (individual episode)

At the Show and Season level, users can batch copy episodes to the device:

```text
Game of Thrones

8 Seasons · 73 Episodes

[ DOWNLOAD TO DEVICE ]
```

The user can choose to download the entire show, a single season, or specific episodes so they can travel or watch without keeping their external drive connected.

---

# 21. Search

Search must be fast and local-first.

Search fields:

- movie title
- TV show title
- episode title
- cast
- director
- creator
- genre
- year

Examples:

```text
interstellar
```

```text
Christopher Nolan
```

```text
Tom Hanks
```

Search should operate against the local database and should not require a network request for normal catalogue search.

---

# 22. Watch State

Store:

```text
UNWATCHED
WATCHED
IN_PROGRESS
```

For movies:

- watched/unwatched
- playback position if available/implemented

For TV:

- episode watched state
- next unwatched episode
- show progress

Watch state is independent of physical storage.

Unplugging a disk must not affect it.

---

# 23. Favorites and Watchlist

Favorites and watchlist are user-owned library state.

They must survive:

- disk disconnection
- rescanning
- metadata refresh
- filename changes where the underlying media identity remains known

---

# 24. Collections

Collections are a separate first-class section.

Examples:

```text
Collections

Die Hard
Marvel Studios
Christopher Nolan
90s Bollywood
My Favorites
```

A collection contains references to library items.

It should not duplicate movie metadata.

Users should eventually be able to:

- create collection
- rename collection
- add/remove movies/shows
- reorder items if desired
- delete collection without deleting media

Collections are **curated**, not automatically generated recommendation feeds.

---

# 25. Offline Copies / Download to Device

REELHOUSE v1.0 must allow the user to copy selected media from removable storage to the local storage of the current device.

### Primary Use Case

> The user wants to watch media without keeping an external HDD connected because keeping the drive connected is inconvenient, unwieldy (e.g. laptop in bed, travel), or power-inefficient.

### Scope of Download Actions

- **Movies**: Single-click `[ ⬇ DOWNLOAD TO DEVICE ]` on the Movie Detail page.
- **TV Shows**: 
  - Entire show batch transfer: `[ ⬇ DOWNLOAD TO DEVICE ]`
  - Season batch transfer: `[ ⬇ DOWNLOAD SEASON ]`
  - Individual episode transfer on the Episode item.

### Copying Engine & Architecture

1. **Background File Copy**:
   - File transfer occurs via a dedicated background task using streaming file I/O (`openRead` -> `openWrite`) with chunked progress reporting.
   - UI displays clear progress percentage, transfer speed, and estimated time remaining.
2. **Storage Allocation**:
   - Files are stored in REELHOUSE's dedicated app data directory (`DEVICE_LOCAL_STORAGE`).
   - File integrity is verified post-copy using file size and quick fingerprinting.
3. **Database Representation**:
   - When copying completes, a new `MediaFile` record is created with:
     - `copyType: DEVICE_LOCAL`
     - `storageId: local-internal`
     - `relativePath: offline_media/<media-id>.<ext>`
     - `available: true`
   - The original `MediaFile` record on the external HDD remains completely untouched with `copyType: ORIGINAL`.
4. **Playback Resolution Hierarchy**:
   When the user taps `PLAY`:
   1. **Device-Local Copy (Priority 1)**: If a `DEVICE_LOCAL` copy exists and is physically present on disk, launch playback from this local copy. No external drive is needed.
   2. **Connected Removable Source (Priority 2)**: If no local copy exists but the original external disk is connected, launch playback from the external disk.
   3. **Disconnected Drive (Fallback)**: If no local copy exists and the external drive is disconnected, display the state-aware `[ CONNECT DISK ]` prompt.
5. **Space Management & Deletion**:
   - Users can delete a local offline copy at any time from the Movie/Episode Detail page or via **Settings → Local Device Storage**.
   - Deleting a device-local copy **never** deletes the original copy from the external drive and **never** deletes the logical movie/show record or its metadata and watch state from the cinema database.

---

# 26. Playback

REELHOUSE v1.0 has **no built-in media player**.

During onboarding ask:

> **Which media player would you like REELHOUSE to use?**

Examples:

- VLC
- mpv
- MPC-HC
- Windows Media Player
- Other application

The preference should be configurable later.

```text
Play
 ↓
Check media availability (Local Offline Copy -> Connected Removable Source)
 ↓
Resolve local file
 ↓
Launch preferred player
```

On desktop this should use the operating system's supported application-launch mechanism.

On Android, use an appropriate Android intent to open the media with the configured/preferred compatible player.

The application must not attempt to implement its own video playback engine.

---

# 27. Web Playback

Web playback is not a v1.0 priority.

The web client should primarily provide the catalogue experience.

If a browser can legitimately access a locally available media resource, playback can be considered later.

Do not build a streaming server merely to enable web playback in v1.0.

---

# 27. Onboarding

First launch should be simple.

### Step 1 — Welcome

```text
Welcome to REELHOUSE

Your personal digital cinema.
```

### Step 2 — Media Player

```text
Choose your preferred media player

VLC
mpv
MPC-HC
System Default
Choose...
```

Allow skipping if appropriate.

### Step 3 — Add Library

```text
Where is your cinema stored?

+ Add Library Location
```

### Step 4 — Scan

Show progress:

```text
Scanning Movies HDD...

1,284 files discovered
842 identified
6 requiring verification
```

### Step 5 — Done

```text
Your cinema is ready.

642 movies
38 TV shows
```

Avoid an excessively long onboarding process.

---

# 28. Settings

Settings should contain:

### Library

- Library locations
- Scan now
- Automatic scanning
- Scan history
- Unidentified media
- Storage status

### Playback

- Preferred media player
- Platform-specific player preference

### Metadata

- Metadata provider
- Refresh metadata
- Cache management
- Attribution/about information

### Appearance

- Theme
- Display preferences

### About

- Version
- Credits
- Metadata attribution

---

# 29. Library Management UI

A dedicated library-management screen should show storage state.

Example:

```text
LIBRARY LOCATIONS

Movies HDD
D:\Movies

● Connected
Last scanned: Today

TV HDD
E:\TV

○ Disconnected
Last scanned: 3 days ago
```

This should be informative but not feel like a technical administration console.

---

# 30. Offline Behavior

When offline:

### Continue working

- Open application
- Browse library
- Search
- View metadata
- View posters
- View collections
- View favorites
- View watch state
- See disk availability

### Require internet

- New metadata lookup
- Metadata refresh
- New artwork retrieval

When internet returns, queued metadata work may resume.

---

# 31. Disconnected Disk Behavior

When a disk disappears:

Do not:

- delete media
- delete metadata
- remove collections
- reset watch state
- ask the user to re-import everything

Instead:

```text
Media status = unavailable
Storage status = disconnected
```

When the disk returns:

```text
Storage detected
      ↓
Verify identity
      ↓
Incremental scan
      ↓
Restore availability
      ↓
Process new files
```

---

# 32. Error Handling

Errors should be understandable.

Bad:

> `ENOENT: filesystem error 0x00000002`

Good:

> **Movies HDD isn't connected.**

> Connect the drive to play movies stored on it.

Technical details can be available under an expandable diagnostic section.

---

# 33. Empty States

Empty states should be useful and attractive.

### No library

> **Your cinema is waiting.**

> Add a folder containing your movies or TV shows to begin.

### No favorites

> **Nothing here yet.**

> Mark a movie or show as a favorite and it will appear here.

### No watchlist

> **Your watchlist is empty.**

Keep the interface calm rather than filling empty space with unnecessary graphics.

---

# 34. Visual Design Direction

REELHOUSE should feel:

- cinematic
- premium
- personal
- modern
- warm
- restrained
- immersive

It should not feel like:

- enterprise software
- a database
- a file explorer
- a generic AI dashboard

### Design priorities

1. Artwork
2. Typography
3. Hierarchy
4. Navigation simplicity
5. State clarity
6. Motion
7. Technical information

Technical information should never overpower the cinema experience.

---

# 35. Navigation

Keep primary navigation minimal.

Suggested:

```text
REELHOUSE

Home
Movies
TV Shows
Collections
Search
```

Secondary:

```text
Settings
```

Desktop may use a compact sidebar/navigation rail.

Mobile should use an appropriate mobile navigation pattern.

Do not reproduce a desktop sidebar on small screens simply because it is easy.

---

# 36. Cards

Cards should primarily communicate:

```text
Poster
Title
Year
State
```

Possible states:

```text
Available
Unavailable
Watched
In Progress
Favorite
```

Avoid displaying all states simultaneously.

The card should remain visually clean.

---

# 37. Motion

Use subtle animation for:

- page transitions
- poster hover/focus
- detail-page artwork
- state changes
- scanning progress
- library synchronization

Animation must never interfere with usability.

Respect reduced-motion settings.

---

# 38. Privacy

REELHOUSE is a personal application.

The application should:

- keep library data local by default
- never upload the user's media files
- never upload file contents to metadata providers
- only send the minimum information necessary for metadata identification
- clearly identify external metadata requests
- avoid telemetry in v1.0 unless explicitly added later

The application should never send an actual movie file to TMDB or another metadata service.

---

# 39. Security

The application does not need complex authentication in v1.0.

Local database files should be protected using normal platform filesystem permissions.

Avoid inventing a login system simply because the application has multiple platforms.

Cross-device synchronization is a future capability.

---

# 40. Metadata Attribution

Because TMDB is the primary metadata provider, the application must include the appropriate TMDB attribution required by its terms.

This should be presented elegantly in:

**Settings → About / Metadata**

rather than disrupting the main cinema experience.

---

# 41. Synchronization Between Devices

Cross-device database synchronization is intentionally **not part of the v1.0 core architecture**.

The local database must nevertheless be structured so that future synchronization is possible.

Potential future model:

```text
Desktop DB
     ↕
Google Drive / sync storage
     ↕
Android DB
```

However, synchronization must not simply overwrite databases blindly.

A future implementation should use:

- stable IDs
- timestamps
- conflict resolution
- separate device-specific media availability

This is future work.

---

# 42. Important Platform Principle

The same movie can have different physical availability on different devices.

Example:

```text
Desktop

Interstellar
✓ Available
Movies HDD connected


Android

Interstellar
○ Unavailable
Movies HDD not connected
```

Both devices can still display the same movie metadata if their local catalogue contains it.

Therefore:

**Media identity and metadata are portable.**

**Physical media availability is device-specific.**

This distinction must be preserved in the data model.

---

# 43. Scanner UX

Scanning should never feel like the application has frozen.

Show:

```text
Scanning...

Movies HDD

Files discovered      1,284
Movies identified       620
TV episodes             481
Needs verification        6

Current:
Interstellar.2014...
```

Allow the user to leave the scanning screen.

Scanning should run as a background task where the platform permits it.

---

# 44. Identification Queue

The application should maintain an:

**Needs Verification**

queue.

Example:

```text
6 items need your attention
```

The user can resolve them later.

This is preferable to blocking an entire library scan waiting for manual input.

---

# 45. Duplicate Media & Multiple Physical Copies

Physical files and logical cinema items are strictly separated. A single movie or TV episode can have multiple physical copies:

```text
Interstellar
   ├── Original Media (Removable HDD 1 / 14 GB)
   ├── Original Media (Removable HDD 2 / 38 GB)
   └── Local Offline Copy (This Device / 14 GB)
```

REELHOUSE represents this as one logical movie with multiple physical `MediaFile` copies.

### Playback Resolution

- If a **device-local offline copy** exists on the current device, REELHOUSE defaults to playing this copy, allowing full offline viewing without requiring external drives to spin up or be plugged in.
- If only **external storage copies** exist, REELHOUSE plays from whichever connected drive is available.
- If multiple external copies are concurrently connected, REELHOUSE defaults to the primary or highest quality copy, while offering a copy-selector in the UI.
- If all storage sources are disconnected and no local copy exists, the UI clearly displays `[ CONNECT DISK ]`.

---

# 46. File Deletion / Missing Files

If a previously known file disappears during a scan:

Do not immediately delete the library entity.

Mark its physical media record unavailable/missing.

This prevents accidental library destruction from temporary filesystem changes.

A future cleanup operation may permanently remove orphaned media records.

---

# 47. Database IDs

Use stable generated IDs for internal entities.

Do not use:

- filenames
- paths
- drive letters

as primary IDs.

External metadata IDs such as TMDB IDs should be stored as external identifiers.

---

# 48. Implementation Structure

Recommended conceptual layers:

```text
UI
│
├── Home
├── Movies
├── TV Shows
├── Collections
├── Search
└── Settings

Domain
│
├── Library
├── Scanner
├── Identification
├── Metadata
├── Availability
├── Watch State
├── Collections
└── Playback Handoff

Data
│
├── SQLite / Drift
├── Metadata Cache
├── Image Cache
└── Platform Storage

Platform
│
├── Filesystem
├── Storage Detection
├── Application Launch
└── Android/Desktop/Web adapters
```

Keep these boundaries clean without creating unnecessary abstractions.

---

# 49. Recommended Implementation Phases

## Phase 1 — Foundation

Implement:

- Flutter project
- navigation
- theme
- database
- core models
- repository layer
- basic settings

## Phase 2 — Library Scanner

Implement:

- storage registration
- recursive scanning
- media file detection
- filename parsing
- incremental scan
- availability detection

## Phase 3 — Metadata

Implement:

- TMDB integration
- search
- identification
- metadata persistence
- image caching
- manual verification

## Phase 4 — Cinema UI

Implement:

- Home
- Movie catalogue
- TV catalogue
- Detail pages
- Search
- Collections
- Favorites
- Watchlist
- Watch state

## Phase 5 — Playback Handoff

Implement:

- preferred player
- platform-specific application launching
- availability-aware Play/Connect UI

## Phase 6 — Polish

Perform a dedicated UI/UX pass:

- typography
- spacing
- animations
- responsive layouts
- loading states
- empty states
- error states
- accessibility
- performance

The final phase must not be skipped.

---

# 50. Performance Requirements

REELHOUSE should be designed for libraries of at least:

**5,000 movies + 1,000 TV shows + tens of thousands of episodes/files.**

The user's current collection is approximately 3.5 TB, so the application should not make assumptions based on small demo libraries.

Catalogue browsing should use database queries and pagination/lazy loading where appropriate.

Do not load the entire library into memory.

Images should be appropriately cached and resized.

---

# 51. Acceptance Criteria

v1.0 is considered successful when the following workflow works:

### Initial setup

1. Install REELHOUSE.
2. Choose preferred media player.
3. Add a media folder.
4. Start scan.
5. Scanner finds media.
6. Movies and TV shows are correctly identified.
7. Metadata is retrieved.
8. Metadata is cached.
9. Catalogue appears.

### Disconnect test

1. Scan HDD.
2. Confirm movie appears.
3. Close/disconnect HDD.
4. Reopen REELHOUSE.
5. Movie remains visible.
6. Metadata remains visible.
7. Play is replaced by an appropriate unavailable/connect state.

### Reconnect test

1. Reconnect HDD.
2. REELHOUSE recognizes the storage.
3. Incremental scan runs.
4. Existing media does not require complete re-identification.
5. Media becomes available.
6. Play action returns.

### New media test

1. Add a new movie to the HDD.
2. Run scan.
3. Only the new/changed media requires processing.
4. Movie appears in Recently Added.

### Identification failure test

1. Scanner encounters ambiguous media.
2. Media is placed in verification queue.
3. User manually selects correct metadata.
4. Association persists.
5. Future scans do not repeatedly ask.

### Playback test

1. Select available movie.
2. Click Play.
3. Preferred external player opens the media.

No internal video player is launched.

### Offline copy & download test

1. Connect external HDD containing media.
2. Navigate to movie or TV episode detail page.
3. Click `[ ⬇ DOWNLOAD TO DEVICE ]`.
4. Observe transfer progress indicator until copy completes.
5. Disconnect the external HDD.
6. Observe library state:
   - Movie/episode continues to show `▶ Play (On Device)`.
   - External HDD copy is marked disconnected under "Your Copies".
   - Local offline copy is marked available.
7. Click `▶ Play`.
8. External player launches using the local offline file without prompting to connect external disk.
9. Click `[ DELETE LOCAL COPY ]` from the detail page or settings.
10. Local file is removed; card and detail page revert to `Connect HDD` when the drive remains disconnected.
11. The movie itself, its metadata, watchlist state, and watch history remain 100% intact.

---

# 52. UX Acceptance Criteria

The application must:

- feel like a personal cinema
- be visually polished
- be responsive
- have a clear visual hierarchy
- make availability obvious
- avoid unnecessary information
- avoid dashboard aesthetics
- avoid generic component-library appearance
- provide excellent poster/backdrop presentation
- remain useful when disks are disconnected
- remain useful without internet access
- never require the user to understand the underlying database

The user should be able to open the application and immediately understand:

> **What do I own?**

> **What's available right now?**

> **What can I watch?**

> **Where is it stored?**

---

# 53. Final Product Definition

REELHOUSE is:

> **A personal digital cinema that remembers your collection even when your disks don't.**

It transforms local media files into a persistent, beautiful catalogue while leaving the user's physical organization completely untouched.

The application owns:

- the library experience
- metadata
- catalogue state
- availability state
- collections
- watch state
- search
- discovery
- playback handoff

The application does **not** own:

- the user's files
- the user's folder structure
- video playback
- media transcoding
- media-server infrastructure

The simplest mental model is:

```text
YOUR FILES
     │
     ▼
REELHOUSE SCANNER
     │
     ▼
PERSONAL CINEMA DATABASE
     │
     ├── Metadata
     ├── Posters
     ├── Shows
     ├── Episodes
     ├── Collections
     ├── Watch State
     └── Availability
     │
     ▼
BEAUTIFUL CINEMA INTERFACE
     │
     ▼
EXTERNAL MEDIA PLAYER
```

**Build the cinema layer. Do not build Plex.**

---

## Implementation Instruction

Antigravity should use this document as the authoritative product specification for REELHOUSE v1.0.

Where a technical implementation choice is not explicitly specified, choose the simplest robust solution consistent with the principles above.

Do not expand the scope by independently adding:

- AI features
- recommendations
- streaming
- media-server functionality
- social functionality
- unnecessary dashboards
- additional services

Prioritize:

**simplicity → correctness → state awareness → visual quality → polish.**

The finished application should feel like a carefully designed personal product, not a generated CRUD application.