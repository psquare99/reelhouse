# REELHOUSE
## Navigation & Home Screen — Implementation Document
### v1.0

---

## 1. Purpose

This document covers two related surfaces: the left navigation rail and the Home screen. Both currently work, but neither reads as "premium personal cinema" yet — the nav rail has an inconsistent accent pattern, and Home opens with administrative status information before it opens with anything cinematic.

This document assumes the color/type token system defined in **REELHOUSE — UI & Theme System — Implementation Document v1.0**. Every color referenced below is a role name from that document (`accent`, `textPrimary`, `surface1`, etc.), not a literal value. If a role doesn't exist yet, add it there first.

---

## 2. Navigation Rail

### 2.1 Current issues

- **Two accents compete for "active state."** The active item currently shows a teal pill with orange label text. Only one accent should ever indicate "you are here" — `accent` (brand orange), consistently, everywhere. Remove the teal usage.
- **No grouping.** Home, Movies, TV Shows, Offline, Collections, Search, and Settings currently sit as one undifferentiated list. They fall into three functional groups and should look like it.

### 2.2 Structure

```
┌─────────────┐
│  [REEL mark]│  ← collapse/expand toggle
├─────────────┤
│  Home       │  ← browse group
│  Movies     │
│  TV Shows   │
├─────────────┤
│  Offline    │  ← library group
│  Collections│
├─────────────┤
│  Search     │  ← utility group
│  Settings   │
└─────────────┘
```

Each group is separated by a `border`-colored hairline and a small vertical gap (12–16px), not by a heading label — the grouping should read structurally, without adding text chrome that competes with Section 16's "avoid unnecessary information" principle.

### 2.3 Active state

- **Expanded rail**: active item gets a filled pill — `accent` at ~14% opacity as background, `accent` full-strength for icon and label text.
- **Collapsed rail**: active item gets a 3px accent-colored bar on the leading edge of the rail, plus full-strength `accent` icon color. No pill (a filled pill reads cramped at 72px width).
- Inactive items in both states: `textSecondary` for icon and label.

### 2.4 Collapse behavior

- Trigger: tapping the REEL mark at the top of the rail.
- Expanded width: ~220px (icon + label). Collapsed width: ~72px (icon only, centered).
- Transition: animate width over ~200ms, ease-out. Labels fade out before the width finishes collapsing (don't let text reflow/wrap mid-animation — hide it at ~50% of the transition).
- Collapsed state shows the label as a hover tooltip, positioned to the right of the icon, using `surface2` background and `textPrimary` text.
- Persist the collapsed/expanded state locally (a simple boolean in app settings/prefs) so it survives app restarts — this is a layout preference, not a per-session UI state.
- **Desktop and tablet landscape** get this rail behavior. **Phone portrait retains the existing bottom NavigationBar** rather than switching to a collapsible rail. On Android tablets or other sufficiently wide layouts, the rail may be used according to the responsive breakpoint already established by the app.

---

## 3. Home Screen

### 3.1 Current issues

- The screen opens with a "Cinema Status" banner (disk connection count) as the first thing seen, every time, regardless of whether anything needs attention. This runs counter to Principle 2.4 ("should not bombard the user with unnecessary information") — connection status is only actionable when something the user expects to be connected, isn't.
- The three "Explore Cinema" tiles (Movies / TV Shows / Offline Library, each showing a raw count) read as KPI cards, not a cinema. They're useful navigation, but shouldn't be the visual anchor of the screen.
- There's no Continue Watching row, which per Section 16 of the main design doc is the section that should exist "only when relevant" — but when it is relevant, it's the most personal, least dashboard-like thing Home can show.

### 3.2 Revised layout, top to bottom

1. **Top bar**: `REELHOUSE` eyebrow mark, settings gear — and a small disk-status indicator (icon + "2/6" count) that replaces the full-width banner. This stays quiet by default.
2. **Hero**: full-width backdrop, ~180–220px tall, with a darkened functional scrim/overlay for text legibility.
   - If something is in progress: show that title, with a progress bar and a `Resume` action button (`accent` fill, `onAccent` text).
   - If nothing is in progress: fall back to the most recently added title's backdrop, no progress bar, action becomes `Play` or `View details`.
   - The hero is never empty — Home should always open with something cinematic, not a conditional gap.
   - **Hero artwork fallback chain:** use the canonical backdrop first; if no usable backdrop exists, use the canonical poster with an appropriate cinematic treatment; if no usable artwork exists, use a neutral themed cinema surface so the hero still occupies its intended space.
3. **Recently Added**: existing poster row, unchanged in mechanics — see Section 3.4 for the data-quality note.
4. **Explore**: the three category entries (Movies, TV Shows, Offline), restyled as compact navigation cards — icon, label, and a **small secondary count** rather than a large headline number. The count is supporting information, not a KPI/metric visual anchor. They're navigation, not the headline.
5. **Favorites / Watchlist rows**: per the main doc's existing spec — only rendered when the user has at least one entry in each. Do not render empty-state placeholders for these on Home.

### 3.3 Disk-status escalation rule

The quiet top-bar indicator is the default state. It should escalate to a visible, dismissible banner only when:
- A storage location the user has previously registered is now unavailable **and** the user has media that depends on it, and
- The user hasn't already dismissed that specific disconnect notice this session.

This keeps the behavior state-aware (per Principle 2.4) without training the user to ignore a banner that shows up unconditionally on every launch.

### 3.4 Data-quality note (not a theme issue, flagging here since it affects the same screen)

The Recently Added row in the current build includes items titled "Character Profile ...", with no year and a placeholder poster — these appear to be bonus/extras content (character art, stills) that the scanner is cataloguing as if it were a movie. This is a scanner-classification issue, not a UI issue, but it directly undermines the "premium" goal of this screen: no hero treatment or spacing fix will make stray extras feel like part of a curated cinema. Recommend tracking this separately against the scanner's file-type/heuristic logic (Section 12 of the main Implementation Design Document) — likely either an extras/bonus-content folder pattern that should be excluded from the primary catalogue, or a non-video file type slipping past the format filter.

**Implementation boundary:** do not modify scanner/classification logic as part of this Navigation & Home Screen work. Track the issue separately as a future scanner milestone.

---

## 4. Acceptance Criteria

- [ ] Nav rail active state uses `accent` only — no secondary accent color anywhere in the rail.
- [ ] Nav rail groups (browse / library / utility) are visually separated by hairline + gap, not by text labels.
- [ ] Clicking the REEL mark toggles collapsed/expanded; state persists across restarts.
- [ ] Collapsed rail shows tooltips on hover for every item.
- [ ] Home opens with a hero (in-progress title or, as fallback, most-recently-added title) — never a status banner as the first element.
- [ ] Hero artwork follows the documented fallback chain when backdrop/poster artwork is unavailable.
- [ ] Disk connection status is a small top-bar indicator by default; it only expands into a banner per the escalation rule in 3.3.
- [ ] Explore tiles are restyled as compact navigation cards, not large stat tiles; counts remain secondary.
- [ ] Favorites/Watchlist rows on Home are omitted entirely when empty — no empty-state placeholder shown.
