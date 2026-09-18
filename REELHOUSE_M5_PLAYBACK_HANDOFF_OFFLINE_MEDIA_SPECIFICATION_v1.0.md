# REELHOUSE — Milestone 5
## Playback Handoff & Offline Media
### Implementation Specification v1.0

**Status:** Architecture contract for V1.0

## 1. Purpose

M5 lets the user copy media that already exists in the REELHOUSE library onto the current device so that the copy can be played without the original external storage being connected.

Core rule:

> **Logical media is permanent; physical media sources are replaceable.**

A device copy is a new physical `MediaSource` for the same logical Movie/Episode. It is never a second logical library item.

## 2. Hard Principles

- Standalone/local-first remains the architecture.
- Saving means **copy**, never move.
- Original source files and folders are never modified by M5.
- Playback remains through the existing external player/VLC architecture.
- M5 never downloads media from the internet.
- M5 never streams, transcodes, compresses, or re-encodes media.
- Presentation code does not perform raw filesystem or transfer orchestration.
- Existing metadata, watch state, playback position, collections, favorites, watchlist and history remain attached to logical media.

## 3. Goals

M5 must support:

1. Application-managed device storage.
2. Device capacity/accessibility detection.
3. Movie, episode and season copy operations.
4. Persistent transfer state.
5. Progress and safe cancellation.
6. Failure/retry handling.
7. Atomic destination completion.
8. Post-copy verification.
9. Registration of completed copies as `MediaSource`s.
10. Normal availability resolution using the new source.
11. Playback of a verified device copy with the original disk disconnected.
12. Removal of a device copy without deleting the logical item or original source.
13. Crash/restart reconciliation.

## 4. Non-goals

No internet downloading, streaming, cloud sync, transcoding, compression, subtitle downloading, torrent functionality, server storage, multi-user quotas, remote-device sync, built-in player, automatic source reorganization, or automatic deletion of originals.

## 5. Physical Storage Model

Conceptually:

```text
Logical Movie
 ├── MediaSource → External HDD
 └── MediaSource → REELHOUSE Device Storage
```

The application-managed destination is a physical storage/source concept separate from user-managed scanned external storage.

A device storage record should be able to identify, as supported by the platform:

- stable storage identity;
- display name;
- root/location;
- total and available capacity;
- accessibility;
- whether it is the designated REELHOUSE copy destination.

Do not use a transient external drive letter as the logical identity of a device storage when a more stable platform identity is available.

### Windows
Use an application-managed directory on an accessible local volume. Do not conflate this with the existing removable-drive identity logic.

### Android
Use a legitimately writable application-managed location appropriate to the supported Android runtime/storage model. Do not add broad storage permissions merely as a shortcut.

A temporarily inaccessible destination must not delete or invalidate logical library records.

## 6. Destination Layout

The destination must be deterministic and application-managed. It must:

- avoid collisions;
- use safe filesystem names;
- tolerate illegal/reserved characters;
- not depend on arbitrary source-folder names;
- survive application restart;
- never overwrite unrelated user files.

Exact platform path/layout is an implementation decision.

## 7. Transfer Scopes

### Movie
Copy one selected movie source.

### Episode
Copy one selected episode source.

### Season
Copy eligible canonical episodes in the selected season as a batch. Extras remain governed by the existing extras policy and do not alter canonical watch aggregation.

A season transfer is a batch of episode transfers, not a new media entity.

## 8. Source Selection

When multiple physical sources exist, choose an actually accessible/playable source. Do not choose a disconnected source merely because its database row exists.

Source selection should consider:

1. accessibility;
2. availability;
3. existence/readability of the media file;
4. existing source semantics.

If no usable source exists, fail clearly. Never invent a path.

## 9. Transfer State Machine

```text
QUEUED → PREPARING → TRANSFERRING → VERIFYING → COMPLETED
   │          │             │             │
   └────────→ CANCELLED     └→ FAILED     └→ FAILED
```

Only `COMPLETED` may expose the destination as a verified playable `MediaSource`.

### QUEUED
Operation accepted.

### PREPARING
Validate source, destination, capacity, destination path and duplicate/active transfer state.

### TRANSFERRING
Copy bytes and report actual byte progress where available.

### VERIFYING
Verify the resulting file before committing it.

### COMPLETED
Atomically finalize the destination, then create/activate the device `MediaSource`.

## 10. Atomic Completion

Use a temporary/incomplete destination during copying:

```text
source
  ↓
destination.tmp
  ↓ verify
destination
  ↓
MediaSource registration
```

The exact temporary naming scheme is implementation-defined.

**Invariant:** an incomplete or unverified file is never a normal playable `MediaSource`.

## 11. Verification

At minimum establish:

- destination exists;
- destination is readable;
- transfer completed without I/O error;
- destination size is consistent with source size.

A full content hash is optional for V1.0 unless implementation review demonstrates that its cost is acceptable and useful. Do not make expensive hashing mandatory without measurement.

## 12. Cancellation and Failure

Cancellation must stop future copying, mark the transfer cancelled, prevent MediaSource registration, and clean temporary artifacts where safe.

Failures may include source disconnect, missing source file, destination failure, insufficient capacity, permission failure, I/O error, application termination, or verification failure.

Failures must never:

- mutate the original source;
- create a duplicate logical item;
- register an incomplete copy;
- report success.

## 13. Crash/Restart Recovery

Transfer state must survive restart when needed for safe reconciliation.

On startup, reconcile incomplete operations with the filesystem:

1. identify non-terminal transfer records;
2. inspect temporary/destination artifacts;
3. remove or safely quarantine incomplete artifacts;
4. place the transfer into a deterministic recoverable state such as `FAILED`/retryable;
5. never register an unverified destination.

Recovery must be idempotent.

## 14. Idempotency

Repeated requests for the same destination media must not create duplicate device copies.

Before starting a transfer, detect:

- existing completed device `MediaSource`;
- active duplicate transfer;
- existing verified destination.

A valid completed copy should be presented as already available, not recopied. Stale partial artifacts must be reconciled before retry.

## 15. Multiple Sources and Availability

M5 integrates with the existing availability model:

- `availableLocally`
- `availableOnRemovableStorage`
- `availableOnMultipleSources`
- `unavailable`

Do not introduce a parallel availability system.

Example:

```text
Movie
 ├── HDD source → disconnected
 └── Device copy → connected
```

The movie remains playable because the device source is available.

The original source remains recorded and untouched.

## 16. Playback Selection

Playback must resolve an actually available source. An accessible device/local source must not be treated as unavailable merely because the original disk is disconnected.

Preserve existing source-selection semantics where multiple accessible sources exist. Do not add arbitrary new precedence rules unless required by implementation.

The existing external VLC/player launcher remains responsible for launching playback.

## 17. Removing Device Copies

Removing a device copy means removing only the REELHOUSE-managed local physical copy.

It must:

- delete only the managed destination file;
- remove/deactivate only its device `MediaSource`;
- preserve the logical media item;
- preserve original external sources;
- preserve metadata and watch state/history.

If physical deletion fails, do not silently pretend the database and filesystem agree; retain enough state for reconciliation.

## 18. Watch Lifecycle

A physical copy does not own watch state.

Playing the device copy updates the same logical Movie/Episode state:

- `watchState`;
- `playbackPositionSeconds`;
- `lastPlayedAt`.

Recently Played therefore continues to refer to the same logical media regardless of which physical source was played.

## 19. Repository and Service Boundaries

Keep the architecture:

```text
Presentation
    ↓
Domain contracts
    ↓
LibraryRepository / Transfer service
    ↓
Database + filesystem/platform infrastructure
```

`LibraryRepository` remains the library-query and user-library-state boundary. Physical transfer orchestration belongs in a dedicated transfer/storage service boundary.

Presentation must not execute raw transfer SQL or filesystem copy logic.

## 20. Persistence

Persistent transfer records are recommended/required wherever state must survive application restart.

A transfer record conceptually contains:

- transfer ID;
- logical target;
- source `MediaSource`;
- destination device storage;
- destination path;
- transfer scope;
- state;
- progress information;
- timestamps;
- failure/cancellation information as needed for recovery.

Exact table/column names are implementation decisions. Any schema change must use a proper Drift migration and must be non-destructive.

## 21. Concurrency

At minimum:

- the same destination media cannot be copied concurrently twice;
- destination paths cannot have competing writers;
- state transitions are atomic;
- a verified destination is registered once.

A single active transfer or a bounded queue is acceptable for V1.0. Complex parallel scheduling is out of scope unless justified.

## 22. Capacity

Before copying, check destination capacity against source size and reasonable filesystem overhead. Avoid starting a transfer that can be rejected immediately for insufficient space.

## 23. UI Contract

Semantic states should include:

- **Not copied:** `SAVE TO DEVICE`
- **Active:** `SAVING…` + real progress
- **Completed:** `ON THIS DEVICE` or equivalent
- **Failed:** `TRY AGAIN`
- **Already present:** do not start duplicate transfer
- **Destination unavailable:** clearly communicate the unavailable destination

Exact labels may be refined during UI work without changing the semantics.

### Movie Detail
Save/remove device-copy action plus normal Play.

### TV Detail
Save episode and Save Season actions. Season progress is aggregate batch progress.

### Episode Row/Detail
Play, Save to Device, progress, completed state, remove copy.

## 24. Offline Behavior

Once verified, a device copy must be playable without internet access. Local metadata must remain sufficient to render the logical item; TMDB/network calls are not part of playback of the copy.

## 25. Disconnect Scenarios

### Source disk disconnects during copy
Fail safely, do not register partial output, retain logical/source records, and allow retry after reconnection.

### Destination becomes unavailable
Fail safely, retain recoverable transfer state, do not register incomplete output, and do not alter source media.

A disconnected external source is never interpreted as deletion of the logical library item.

## 26. Security / Filesystem Safety

The transfer subsystem must:

- restrict writes to the managed destination;
- validate/sanitize destination components;
- prevent path traversal;
- avoid overwriting unrelated files;
- handle symlink/reparse-point escape risks appropriately;
- never execute copied media as code;
- never modify source filesystem content.

## 27. Metadata and Artwork

M5 copies media files, not logical metadata records. Metadata/artwork remain associated with the logical media item.

Do not create duplicate Movie/TV/Episode metadata merely because a physical copy exists.

## 28. Conceptual Transfer API

The final Dart API should follow project conventions, but the service should conceptually support:

```text
saveMovieToDevice(movieId)
saveEpisodeToDevice(episodeId)
saveSeasonToDevice(showId, seasonId)
cancelTransfer(transferId)
retryTransfer(transferId)
removeDeviceCopy(mediaId)
watchTransfer(transferId)
reconcileTransfers()
```

These are contracts, not mandatory method names.

## 29. Milestone Breakdown

### M5.1 — Device Storage Foundation

- Device-storage abstraction.
- Application-managed destination.
- Registration and stable identity.
- Capacity/accessibility.
- Windows/Android handling.

**Acceptance:** destination resolves after restart; unavailable destination does not corrupt library state; capacity is queryable.

### M5.2 — Transfer Engine

- Transfer domain model.
- Persistent lifecycle.
- Movie/episode/season transfers.
- Source resolution.
- Byte copy.
- Progress/cancellation/failure.
- Duplicate prevention.

**Acceptance:** valid media can be copied; original remains untouched; partial copy is not playable.

### M5.3 — Verification & Recovery

- Atomic temporary files.
- Verification.
- Restart reconciliation.
- Retry and idempotency.

**Acceptance:** interrupted copies never become MediaSources; verified copies survive restart; retry is safe.

### M5.4 — MediaSource & Availability Integration

- Completed-copy MediaSource registration.
- Availability integration.
- Device-source removal.
- Playback source selection.

**Acceptance:** device copy is the same logical item; original source remains; disconnected original disk does not block playback when local copy exists.

### M5.5 — Playback & UI Integration

- Save-to-device actions.
- Progress/completed/error states.
- Movie/episode/season workflows.
- Remove-copy action.
- External-player playback.

**Acceptance:** user can save, disconnect original media, and play the verified local copy while preserving watch lifecycle.

### M5.6 — Hardening & Acceptance

- Integration tests.
- Platform checks.
- Storage failure tests.
- Disconnect/reconnect tests.
- Restart recovery.
- Duplicate-transfer tests.
- Large-file tests.
- Final architecture audit.

**Acceptance:** all invariants below hold and the repository is clean.

## 30. Test Matrix

### Happy path

- Movie copy.
- Episode copy.
- Season copy.
- Successful verification.
- Playback from device copy.

### Failure

- Source unavailable.
- Source disconnect during copy.
- Destination unavailable.
- Insufficient space.
- Permission failure.
- Destination I/O failure.
- Verification failure.
- Cancellation.

### Recovery

- Application termination during transfer.
- Restart reconciliation.
- Retry.
- Stale temporary artifact.
- Already-completed destination.

### Identity

- Device copy does not create duplicate logical media.
- Multiple physical sources remain attached to one logical item.

### Availability

- Original disconnected + device copy available.
- Both available.
- Device copy removed.
- Device destination unavailable.

### Watch lifecycle

- Play copied media.
- Preserve watch state.
- Preserve playback position.
- Preserve `lastPlayedAt`.
- Recently Played still references the same logical media.

### UI

- Save action.
- Real progress.
- Completion.
- Failure/retry.
- Remove copy.
- Season aggregate progress.

## 31. Hard Invariants

1. **Copy never means move.**
2. **Original media is never modified by M5.**
3. **A physical copy never creates a duplicate logical media item.**
4. **An unverified file is never registered as a playable MediaSource.**
5. **A failed transfer never reports success.**
6. **A disconnected source never causes logical library deletion.**
7. **A device copy participates in the normal availability model.**
8. **Playback uses the existing external-player architecture.**
9. **Watch state belongs to logical media, not physical copies.**
10. **Removing a device copy does not remove the original source or logical media.**
11. **A completed device copy does not require internet access for playback.**
12. **M5 introduces no streaming, transcoding, or internet downloading.**
13. **Transfer recovery is deterministic and safe after restart.**
14. **Duplicate transfers cannot create conflicting device copies.**
15. **Presentation code does not perform raw transfer/storage/database orchestration.**

## 32. Open Implementation Decisions

These remain deliberately open until the relevant milestone:

- Exact Windows destination directory.
- Exact Android storage API/location.
- Automatic vs user-confirmed device-storage registration.
- Transfer concurrency/queue policy.
- Full-hash vs minimum verification strategy.
- Exact transfer persistence schema.
- Exact user-facing terminology.
- Season-transfer pause support.
- Background transfer/notification behavior subject to platform capabilities.

These decisions must not violate the hard invariants.

## 33. Definition of Done

The end-to-end V1.0 workflow is:

```text
Existing library media
        ↓
SAVE TO DEVICE
        ↓
Resolve destination + source
        ↓
Validate capacity/accessibility
        ↓
Copy to temporary destination
        ↓
Verify
        ↓
Commit destination
        ↓
Register MediaSource
        ↓
Device copy becomes available
        ↓
Disconnect original disk
        ↓
Same logical media remains in library
        ↓
PLAY
        ↓
External player launches device copy
```

Removal:

```text
Remove device copy
        ↓
Delete managed physical copy
        ↓
Remove device MediaSource
        ↓
Original MediaSource remains
        ↓
Logical media remains
        ↓
Metadata/watch state/history remain
```

This document is the M5 architecture contract. Implementation should proceed in the bounded M5.1 → M5.6 order, with each milestone tested and committed before the next begins.
