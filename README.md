# REELHOUSE — Personal Digital Cinema

> Turn a collection of locally stored media files into a beautiful, persistent, searchable personal cinema.

REELHOUSE is a personal digital cinema application designed to organize and present an existing collection of movies and TV shows stored on local disks.

**REELHOUSE is not a media player, media server, file manager, or Plex clone.**

---

## Core Principles

1. **The library is permanent; disks are sources**  
   A disconnected drive never deletes movies from the library. The application retains them and clearly marks them unavailable with a "Connect Disk" prompt.
2. **Local First**  
   Browsing your cinema requires no internet connection. All metadata, indexes, and states are stored locally.
3. **Your folders are none of our business**  
   REELHOUSE never requires reorganizing, renaming, or touching physical folders. It builds a logical catalogue on top of your existing files.
4. **Dynamic means state-aware**  
   Actions reflect reality. If a movie's storage is connected, it shows **PLAY**. If disconnected, it shows **CONNECT DISK**.
5. **No Built-in Player**  
   REELHOUSE hands off playback to the user's preferred external media player (VLC, mpv, MPC-HC, or system default) without locking files or hosting streaming servers.
6. **Designed, not Generated**  
   Warm, cinematic, artwork-first interface avoiding generic SaaS dashboards and AI clutter.
7. **Media location is separate from media identity (Download to Device)**  
   Logical media items exist independently of their physical copies. Users can copy selected media from removable HDDs to local device storage ("Download to Device") to enjoy untethered playback without keeping external drives connected.

---

## Architecture & Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Desktop, Android, Web)
- **Local Database**: SQLite with [Drift](https://drift.simonbinder.eu/)
- **Metadata Provider**: [The Movie Database (TMDB)](https://www.themoviedb.org/) with local persistent caching
- **Storage Identity**: Platform-native volume/filesystem identity (Volume Serial / GUID / UUID) first, with optional `.reelhouse_source` marker files as secondary fallback.

---

## Milestone Progress

- **M0 — Baseline Setup**: Git repository, project foundations, authoritative design document.
- **M1 — Foundation & Core Architecture**: Cinematic design system, Drift SQLite database with physical `MediaSource` and transient `TransferJob` separation, platform storage adapters (`WindowsStorageAdapter`, `AndroidStorageAdapter`), shell navigation.
- **M2 — Storage & Scanner**: Non-blocking media scanner, filename heuristic parser (movies, TV series, codecs, resolutions), incremental library synchronization engine (discovering new files, updating disconnected states without deleting catalogue items, restoring reconnected sources), live storage monitoring service (`StorageMonitorService`), and live scanning progress UX in Settings.

---

## Documentation

For full product architecture, data models, and specifications, refer to [REELHOUSE — Implementation Design Document v1.0.md](./REELHOUSE%20%E2%80%94%20Implementation%20Design%20Document%20v1.0.md).

